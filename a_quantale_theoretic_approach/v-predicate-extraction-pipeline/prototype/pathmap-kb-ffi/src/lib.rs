use perspective_pathmap_prototype::overlay::{FactKey, OverlayAction, OverlayStore};
use perspective_pathmap_prototype::snapshot::SnapshotManager;
use perspective_pathmap_prototype::{ImmutableShardStore, MappedShardIndex, ResultRow};
use std::collections::HashMap;
use std::ffi::c_void;
use std::ffi::{CStr, CString};
use std::io;
use std::os::raw::c_char;
use std::path::PathBuf;
use std::sync::{Mutex, OnceLock};

#[derive(Default)]
struct RegisteredIndex {
    root: PathBuf,
    store: Option<ImmutableShardStore>,
    cache_capacity: usize,
    overlay: Option<OverlayStore>,
    snapshot_root: Option<PathBuf>,
}

enum QueryScope<'a> {
    Algebra { concept: &'a str, family: &'a str },
    Properties { concept: &'a str },
    Worlds { concept: &'a str, property: &'a str },
    Specification { concept: &'a str },
}

impl QueryScope<'_> {
    fn matches(&self, key: &FactKey) -> bool {
        match self {
            Self::Algebra { concept, family } => key.concept == *concept && key.family == *family,
            Self::Properties { concept } => key.concept == *concept && key.family == "property",
            Self::Worlds { concept, property } => {
                key.concept == *concept
                    && key.family == "property-world"
                    && key.feature == *property
            }
            Self::Specification { concept } => key.concept == *concept,
        }
    }
}

#[derive(Default)]
struct Registry {
    indexes: HashMap<String, RegisteredIndex>,
}

static REGISTRY: OnceLock<Mutex<Registry>> = OnceLock::new();

fn registry() -> &'static Mutex<Registry> {
    REGISTRY.get_or_init(|| Mutex::new(Registry::default()))
}

fn fields(input: &str, expected: usize) -> Result<Vec<&str>, String> {
    let fields: Vec<_> = input.split('\t').collect();
    if fields.len() != expected {
        return Err(format!(
            "expected {expected} tab-separated fields, received {}",
            fields.len()
        ));
    }
    Ok(fields)
}

fn with_index(
    handle: &str,
    perspective: &str,
    scope: QueryScope<'_>,
    query: impl FnOnce(&MappedShardIndex) -> io::Result<Vec<ResultRow>>,
) -> Result<Vec<ResultRow>, String> {
    let mut registry = registry()
        .lock()
        .map_err(|_| "index registry is poisoned".to_owned())?;
    let registered = registry
        .indexes
        .get_mut(handle)
        .ok_or_else(|| format!("unknown index handle: {handle}"))?;
    if registered.store.is_none() {
        registered.store = Some(
            ImmutableShardStore::open_with_capacity(&registered.root, registered.cache_capacity)
                .map_err(|error| format!("failed to open immutable index: {error}"))?,
        );
    }
    let shard = registered
        .store
        .as_ref()
        .unwrap()
        .load(perspective)
        .map_err(|error| format!("failed to load perspective {perspective}: {error}"))?;
    let shard = shard
        .lock()
        .map_err(|_| format!("mapped shard lock is poisoned: {perspective}"))?;
    let rows = query(&shard).map_err(|error| format!("mapped query failed: {error}"))?;
    Ok(registered
        .overlay
        .as_ref()
        .map(|overlay| {
            overlay
                .overlay()
                .merge_matching(perspective, rows.clone(), |key| scope.matches(key))
        })
        .unwrap_or(rows))
}

fn safe_atom(value: &str) -> String {
    let safe = !value.is_empty()
        && value
            .bytes()
            .all(|byte| !byte.is_ascii_whitespace() && !matches!(byte, b'(' | b')' | b'"' | b';'));
    if safe {
        value.to_owned()
    } else {
        let escaped = value
            .replace('\\', "\\\\")
            .replace('"', "\\\"")
            .replace('\n', "\\n")
            .replace('\r', "\\r")
            .replace('\t', "\\t");
        format!("\"{escaped}\"")
    }
}

fn tv(strength: f32, confidence: f32) -> String {
    format!("(stv {strength:.3} {confidence:.3})")
}

fn optional_tv(row: &ResultRow) -> String {
    match (row.payload_strength, row.payload_confidence) {
        (Some(strength), Some(confidence)) => tv(strength, confidence),
        _ => "()".to_owned(),
    }
}

fn row_to_metta(row: &ResultRow) -> String {
    let feature = match row.family {
        "predicate" | "axiom" => row.feature.clone(),
        _ => safe_atom(&row.feature),
    };
    let evidence = safe_atom(&row.evidence);
    let truth = tv(row.strength, row.confidence);
    match row.family {
        "sort" => format!("(sort-row {feature} {truth} {evidence})"),
        "operation" => format!(
            "(operation {feature} {} {truth} {} {evidence} {})",
            row.payload.as_deref().unwrap_or("()"),
            optional_tv(row),
            row.payload_evidence
                .as_deref()
                .map(safe_atom)
                .unwrap_or_else(|| "()".to_owned())
        ),
        "predicate" => format!("(predicate {feature} {truth} {evidence})"),
        "axiom" => format!("(axiom {feature} {truth} {evidence})"),
        "property" => format!("(property {feature} {truth} {evidence})"),
        "property-world" => format!(
            "(property-world {feature} {} {} {truth} {evidence})",
            safe_atom(row.world.as_deref().unwrap_or("")),
            safe_atom(row.evaluation_perspective.as_deref().unwrap_or(""))
        ),
        other => format!("(row {} {feature} {truth} {evidence})", safe_atom(other)),
    }
}

fn rows_to_metta(rows: &[ResultRow]) -> String {
    let mut output = String::from("(");
    for (index, row) in rows.iter().enumerate() {
        if index != 0 {
            output.push(' ');
        }
        output.push_str(&row_to_metta(row));
    }
    output.push(')');
    output
}

fn specification_to_metta(rows: &[ResultRow]) -> String {
    let mut output = String::from("(specification");
    for family in [
        "sort",
        "operation",
        "predicate",
        "axiom",
        "property",
        "property-world",
    ] {
        output.push(' ');
        let family_rows: Vec<_> = rows
            .iter()
            .filter(|row| row.family == family)
            .cloned()
            .collect();
        output.push_str(&rows_to_metta(&family_rows));
    }
    output.push(')');
    output
}

fn execute(command: &str, input: &str) -> Result<String, String> {
    match command {
        "open" | "open-capacity" | "open-overlay" | "open-snapshot" | "open-snapshot-overlay" => {
            let expected = match command {
                "open" => 2,
                "open-capacity" | "open-snapshot" => 3,
                _ => 4,
            };
            let parts = fields(input, expected)?;
            let handle = parts[0];
            let snapshot_root = matches!(command, "open-snapshot" | "open-snapshot-overlay")
                .then(|| PathBuf::from(parts[1]));
            let root = if let Some(snapshot_root) = &snapshot_root {
                SnapshotManager::open(snapshot_root)
                    .and_then(|manager| manager.current_index())
                    .map_err(|error| format!("failed to resolve current snapshot: {error}"))?
            } else {
                PathBuf::from(parts[1])
            };
            let cache_capacity = if command != "open" {
                parts[expected - 1]
                    .parse::<usize>()
                    .map_err(|_| "cache capacity must be a positive integer".to_owned())?
            } else {
                std::env::var("PATHMAP_KB_SHARD_CACHE_CAPACITY")
                    .ok()
                    .and_then(|value| value.parse().ok())
                    .unwrap_or(8)
            };
            if cache_capacity == 0 {
                return Err("cache capacity must be positive".to_owned());
            }
            if handle.is_empty() {
                return Err("index handle must not be empty".to_owned());
            }
            if !root.join("manifest.tsv").is_file() {
                return Err(format!("index manifest not found under {}", root.display()));
            }
            let mut registry = registry()
                .lock()
                .map_err(|_| "index registry is poisoned".to_owned())?;
            registry.indexes.insert(
                handle.to_owned(),
                RegisteredIndex {
                    root,
                    store: None,
                    cache_capacity,
                    overlay: if matches!(command, "open-overlay" | "open-snapshot-overlay") {
                        Some(
                            OverlayStore::open(PathBuf::from(parts[2]))
                                .map_err(|error| format!("failed to open overlay: {error}"))?,
                        )
                    } else {
                        None
                    },
                    snapshot_root,
                },
            );
            Ok("true".to_owned())
        }
        "close" => {
            let parts = fields(input, 1)?;
            let removed = registry()
                .lock()
                .map_err(|_| "index registry is poisoned".to_owned())?
                .indexes
                .remove(parts[0])
                .is_some();
            Ok(if removed { "true" } else { "false" }.to_owned())
        }
        "cache-stats" => {
            let parts = fields(input, 1)?;
            let registry = registry()
                .lock()
                .map_err(|_| "index registry is poisoned".to_owned())?;
            let registered = registry
                .indexes
                .get(parts[0])
                .ok_or_else(|| format!("unknown index handle: {}", parts[0]))?;
            let stats = registered
                .store
                .as_ref()
                .map(ImmutableShardStore::cache_stats)
                .unwrap_or_default();
            Ok(format!(
                "(cache-stats {} {} {} {} {})",
                stats.hits, stats.loads, stats.evictions, stats.resident, stats.capacity
            ))
        }
        "overlay-apply" => {
            let parts = fields(input, 2)?;
            let action: OverlayAction = serde_json::from_str(parts[1])
                .map_err(|error| format!("invalid overlay action: {error}"))?;
            let mut registry = registry()
                .lock()
                .map_err(|_| "index registry is poisoned".to_owned())?;
            let overlay = registry
                .indexes
                .get_mut(parts[0])
                .and_then(|registered| registered.overlay.as_mut())
                .ok_or_else(|| format!("handle has no mutable overlay: {}", parts[0]))?;
            overlay
                .apply_action(action)
                .map(|changed| changed.to_string())
                .map_err(|error| format!("failed to persist overlay: {error}"))
        }
        "overlay-clear" => {
            let parts = fields(input, 1)?;
            let mut registry = registry()
                .lock()
                .map_err(|_| "index registry is poisoned".to_owned())?;
            let overlay = registry
                .indexes
                .get_mut(parts[0])
                .and_then(|registered| registered.overlay.as_mut())
                .ok_or_else(|| format!("handle has no mutable overlay: {}", parts[0]))?;
            overlay
                .clear()
                .map(|()| "true".to_owned())
                .map_err(|error| format!("failed to clear overlay: {error}"))
        }
        "snapshot-switch" => {
            let parts = fields(input, 2)?;
            let mut registry = registry()
                .lock()
                .map_err(|_| "index registry is poisoned".to_owned())?;
            let registered = registry
                .indexes
                .get_mut(parts[0])
                .ok_or_else(|| format!("unknown index handle: {}", parts[0]))?;
            let snapshot_root = registered
                .snapshot_root
                .as_ref()
                .ok_or_else(|| format!("handle is not snapshot-managed: {}", parts[0]))?;
            let root = SnapshotManager::open(snapshot_root)
                .and_then(|manager| manager.switch(parts[1]))
                .map_err(|error| format!("failed to switch snapshot: {error}"))?;
            registered.root = root;
            registered.store = None;
            Ok("true".to_owned())
        }
        "query-algebra" => {
            let parts = fields(input, 4)?;
            let rows = with_index(
                parts[0],
                parts[1],
                QueryScope::Algebra {
                    concept: parts[2],
                    family: parts[3],
                },
                |index| index.query_algebra(parts[2], parts[3]),
            )?;
            Ok(rows_to_metta(&rows))
        }
        "query-properties" => {
            let parts = fields(input, 3)?;
            let rows = with_index(
                parts[0],
                parts[1],
                QueryScope::Properties { concept: parts[2] },
                |index| index.query_properties(parts[1], parts[2]),
            )?;
            Ok(rows_to_metta(&rows))
        }
        "query-worlds" => {
            let parts = fields(input, 4)?;
            let rows = with_index(
                parts[0],
                parts[1],
                QueryScope::Worlds {
                    concept: parts[2],
                    property: parts[3],
                },
                |index| index.query_worlds(parts[1], parts[2], parts[3]),
            )?;
            Ok(rows_to_metta(&rows))
        }
        "build-specification" => {
            let parts = fields(input, 3)?;
            let rows = with_index(
                parts[0],
                parts[1],
                QueryScope::Specification { concept: parts[2] },
                |index| index.build_specification(parts[2]),
            )?;
            Ok(specification_to_metta(&rows))
        }
        _ => Err(format!("unknown command: {command}")),
    }
}

fn query_rows(command: &str, input: &str) -> Result<Vec<ResultRow>, String> {
    let command = command.strip_suffix("-detailed").unwrap_or(command);
    match command {
        "query-algebra" => {
            let parts = fields(input, 4)?;
            with_index(
                parts[0],
                parts[1],
                QueryScope::Algebra {
                    concept: parts[2],
                    family: parts[3],
                },
                |index| index.query_algebra(parts[2], parts[3]),
            )
        }
        "query-properties" => {
            let parts = fields(input, 3)?;
            with_index(
                parts[0],
                parts[1],
                QueryScope::Properties { concept: parts[2] },
                |index| index.query_properties(parts[1], parts[2]),
            )
        }
        "query-worlds" => {
            let parts = fields(input, 4)?;
            with_index(
                parts[0],
                parts[1],
                QueryScope::Worlds {
                    concept: parts[2],
                    property: parts[3],
                },
                |index| index.query_worlds(parts[1], parts[2], parts[3]),
            )
        }
        "build-specification" => {
            let parts = fields(input, 3)?;
            with_index(
                parts[0],
                parts[1],
                QueryScope::Specification { concept: parts[2] },
                |index| index.build_specification(parts[2]),
            )
        }
        _ => Err(format!("command does not return rows: {command}")),
    }
}

#[repr(C)]
pub struct ByteSlice {
    pointer: *const u8,
    length: usize,
}

impl ByteSlice {
    fn new(value: Option<&str>) -> Self {
        match value {
            Some(value) => Self {
                pointer: value.as_ptr(),
                length: value.len(),
            },
            None => Self {
                pointer: std::ptr::null(),
                length: 0,
            },
        }
    }
}

#[repr(C)]
pub struct RowView {
    family: u8,
    feature: ByteSlice,
    world: ByteSlice,
    evaluation_perspective: ByteSlice,
    payload: ByteSlice,
    evidence: ByteSlice,
    payload_evidence: ByteSlice,
    provenance: ByteSlice,
    origin: ByteSlice,
    payload_provenance: ByteSlice,
    payload_origin: ByteSlice,
    strength: f64,
    confidence: f64,
    payload_strength: f64,
    payload_confidence: f64,
    flags: u8,
}

impl RowView {
    fn new(row: &ResultRow) -> Result<Self, String> {
        fn metta_float(value: f32) -> f64 {
            (value as f64 * 1_000.0).round() / 1_000.0
        }

        let family = match row.family {
            "sort" => 0,
            "operation" => 1,
            "predicate" => 2,
            "axiom" => 3,
            "property" => 4,
            "property-world" => 5,
            family => return Err(format!("unsupported result family: {family}")),
        };
        let mut flags = 0;
        if row.payload_strength.is_some() && row.payload_confidence.is_some() {
            flags |= 1;
        }
        Ok(Self {
            family,
            feature: ByteSlice::new(Some(&row.feature)),
            world: ByteSlice::new(row.world.as_deref()),
            evaluation_perspective: ByteSlice::new(row.evaluation_perspective.as_deref()),
            payload: ByteSlice::new(row.payload.as_deref()),
            evidence: ByteSlice::new(Some(&row.evidence)),
            payload_evidence: ByteSlice::new(row.payload_evidence.as_deref()),
            provenance: ByteSlice::new(row.provenance.as_deref()),
            origin: ByteSlice::new(row.origin),
            payload_provenance: ByteSlice::new(row.payload_provenance.as_deref()),
            payload_origin: ByteSlice::new(row.payload_origin),
            strength: metta_float(row.strength),
            confidence: metta_float(row.confidence),
            payload_strength: metta_float(row.payload_strength.unwrap_or_default()),
            payload_confidence: metta_float(row.payload_confidence.unwrap_or_default()),
            flags,
        })
    }
}

pub type RowVisitor = unsafe extern "C" fn(*mut c_void, *const RowView) -> i32;

fn c_string(value: String) -> *mut c_char {
    CString::new(value)
        .unwrap_or_else(|_| CString::new("ERR: response contained a NUL byte").unwrap())
        .into_raw()
}

#[unsafe(no_mangle)]
pub extern "C" fn rust_pathmap_kb(command: *const c_char, input: *const c_char) -> *mut c_char {
    if command.is_null() || input.is_null() {
        return std::ptr::null_mut();
    }
    let command = match unsafe { CStr::from_ptr(command) }.to_str() {
        Ok(value) => value,
        Err(_) => return c_string("ERR: command is not UTF-8".to_owned()),
    };
    let input = match unsafe { CStr::from_ptr(input) }.to_str() {
        Ok(value) => value,
        Err(_) => return c_string("ERR: input is not UTF-8".to_owned()),
    };
    match std::panic::catch_unwind(|| execute(command, input)) {
        Ok(Ok(output)) => c_string(output),
        Ok(Err(error)) => c_string(format!("ERR: {error}")),
        Err(_) => c_string("ERR: pathmap query panicked".to_owned()),
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn rust_pathmap_kb_visit(
    command: *const c_char,
    input: *const c_char,
    visitor: Option<RowVisitor>,
    context: *mut c_void,
) -> *mut c_char {
    if command.is_null() || input.is_null() || visitor.is_none() {
        return c_string("ERR: invalid typed-query argument".to_owned());
    }
    let command = match unsafe { CStr::from_ptr(command) }.to_str() {
        Ok(value) => value,
        Err(_) => return c_string("ERR: command is not UTF-8".to_owned()),
    };
    let input = match unsafe { CStr::from_ptr(input) }.to_str() {
        Ok(value) => value,
        Err(_) => return c_string("ERR: input is not UTF-8".to_owned()),
    };
    let visitor = visitor.unwrap();
    match std::panic::catch_unwind(|| -> Result<(), String> {
        for row in query_rows(command, input)? {
            let view = RowView::new(&row)?;
            if unsafe { visitor(context, &view) } == 0 {
                return Err("Prolog rejected a result row".to_owned());
            }
        }
        Ok(())
    }) {
        Ok(Ok(())) => std::ptr::null_mut(),
        Ok(Err(error)) => c_string(format!("ERR: {error}")),
        Err(_) => c_string("ERR: typed pathmap query panicked".to_owned()),
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn rust_pathmap_kb_string_free(pointer: *mut c_char) {
    if !pointer.is_null() {
        unsafe { drop(CString::from_raw(pointer)) };
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use perspective_pathmap_prototype::overlay::{OverlayFact, OverlayLayer};
    use perspective_pathmap_prototype::{BuildStats, Index};
    use std::fs;
    use std::time::{SystemTime, UNIX_EPOCH};

    #[test]
    fn unsafe_atoms_are_quoted() {
        assert_eq!(safe_atom("plain_atom"), "plain_atom");
        assert_eq!(safe_atom("two words"), "\"two words\"");
    }

    #[test]
    fn typed_view_carries_fact_and_payload_provenance() {
        let row = ResultRow {
            concept: "computer".to_owned(),
            family: "operation",
            feature: "compute".to_owned(),
            world: None,
            payload: Some("(-> computer output)".to_owned()),
            evidence: "fact_ev".to_owned(),
            strength: 0.9,
            confidence: 0.8,
            payload_strength: Some(1.0),
            payload_confidence: Some(0.95),
            payload_evidence: Some("signature_ev".to_owned()),
            evaluation_perspective: None,
            provenance: Some("(provenance source fact)".to_owned()),
            origin: Some("asserted"),
            payload_provenance: Some("(provenance source signature)".to_owned()),
            payload_origin: Some("generated"),
        };
        let view = RowView::new(&row).unwrap();
        assert_eq!(
            view.provenance.length,
            row.provenance.as_ref().unwrap().len()
        );
        assert_eq!(view.origin.length, "asserted".len());
        assert_eq!(
            view.payload_provenance.length,
            row.payload_provenance.as_ref().unwrap().len()
        );
        assert_eq!(view.payload_origin.length, "generated".len());
    }

    #[test]
    fn ffi_build_specification_preserves_world_evaluation_perspective() {
        let property = "(: property_ev (≞ (has_scoped_property property_ev computer behavioral_process process_property process_information) (stv 0.900 0.800)))";
        let world = "(: world_ev (≞ (scoped_property_holds_in world_ev process_property spatial_context data_center) (stv 0.850 0.900)))";
        let mut index = Index::default();
        let mut stats = BuildStats::default();
        index.ingest_property_line(property, &mut stats).unwrap();
        index.ingest_property_line(world, &mut stats).unwrap();
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let root = std::env::temp_dir().join(format!("pathmap-ffi-integration-{nonce}"));
        index.save(&root, stats).unwrap();

        let handle = format!("integration_{nonce}");
        execute("open", &format!("{handle}\t{}", root.display())).unwrap();
        let output = execute(
            "build-specification",
            &format!("{handle}\tbehavioral_process\tcomputer"),
        )
        .unwrap();
        assert!(output.contains("property-world process_information data_center spatial_context"));
        let rows = query_rows(
            "query-worlds",
            &format!("{handle}\tbehavioral_process\tcomputer\tprocess_information"),
        )
        .unwrap();
        assert_eq!(
            rows[0].evaluation_perspective.as_deref(),
            Some("spatial_context")
        );
        execute("close", &handle).unwrap();
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn ffi_mmap_cache_is_bounded_and_legacy_results_match() {
        let mut index = Index::default();
        let mut stats = BuildStats::default();
        for (perspective, concept, sort, evidence) in [
            ("p1", "c1", "s1", "e1"),
            ("p2", "c2", "s2", "e2"),
            ("p3", "c3", "s3", "e3"),
        ] {
            let line = format!(
                "(: {evidence} (≞ (has_sort {evidence} {concept} {perspective} {sort}) (stv 1.000 0.900)))"
            );
            index.ingest_algebra_line(&line, &mut stats).unwrap();
        }
        let expected = index.query_algebra("p1", "c1", "sort");
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let root = std::env::temp_dir().join(format!("pathmap-ffi-cache-{nonce}"));
        index.save(&root, stats).unwrap();
        let handle = format!("cache_{nonce}");
        execute("open-capacity", &format!("{handle}\t{}\t2", root.display())).unwrap();
        assert_eq!(
            query_rows("query-algebra", &format!("{handle}\tp1\tc1\tsort")).unwrap(),
            expected
        );
        query_rows("query-algebra", &format!("{handle}\tp2\tc2\tsort")).unwrap();
        query_rows("query-algebra", &format!("{handle}\tp3\tc3\tsort")).unwrap();
        assert_eq!(
            execute("cache-stats", &handle).unwrap(),
            "(cache-stats 0 3 1 2 2)"
        );
        execute("close", &handle).unwrap();
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn ffi_queries_merge_durable_overlay_updates_and_tombstones() {
        let mut index = Index::default();
        let mut stats = BuildStats::default();
        index
            .ingest_algebra_line(
                "(: base_ev (≞ (has_sort base_ev computer taxonomic_kind artifact) (stv 0.700 0.800)))",
                &mut stats,
            )
            .unwrap();
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let root = std::env::temp_dir().join(format!("pathmap-ffi-overlay-{nonce}"));
        index.save(&root, stats).unwrap();
        let overlay_path = root.parent().unwrap().join(format!("overlay-{nonce}.json"));
        let handle = format!("overlay_{nonce}");
        execute(
            "open-overlay",
            &format!(
                "{handle}\t{}\t{}\t2",
                root.display(),
                overlay_path.display()
            ),
        )
        .unwrap();
        let key = FactKey {
            perspective: "taxonomic_kind".to_owned(),
            concept: "computer".to_owned(),
            family: "sort".to_owned(),
            feature: "artifact".to_owned(),
            world: None,
            evaluation_perspective: None,
        };
        let upsert = OverlayAction::Upsert {
            fact: OverlayFact {
                key: key.clone(),
                payload: None,
                evidence: "corrected_ev".to_owned(),
                strength: 1.0,
                confidence: 0.99,
                payload_strength: None,
                payload_confidence: None,
                payload_evidence: None,
                provenance: Some("(manual correction)".to_owned()),
                payload_provenance: None,
                layer: OverlayLayer::Corrected,
            },
        };
        execute(
            "overlay-apply",
            &format!("{handle}\t{}", serde_json::to_string(&upsert).unwrap()),
        )
        .unwrap();
        let rows = query_rows(
            "query-algebra",
            &format!("{handle}\ttaxonomic_kind\tcomputer\tsort"),
        )
        .unwrap();
        assert_eq!(rows.len(), 1);
        assert_eq!(rows[0].evidence, "corrected_ev");

        let retract = OverlayAction::Retract {
            key,
            layer: OverlayLayer::Corrected,
        };
        execute(
            "overlay-apply",
            &format!("{handle}\t{}", serde_json::to_string(&retract).unwrap()),
        )
        .unwrap();
        assert!(
            query_rows(
                "query-algebra",
                &format!("{handle}\ttaxonomic_kind\tcomputer\tsort"),
            )
            .unwrap()
            .is_empty()
        );
        execute("close", &handle).unwrap();
        fs::remove_dir_all(root).unwrap();
        fs::remove_file(overlay_path).unwrap();
    }

    #[test]
    fn ffi_snapshot_switch_invalidates_mapped_cache() {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let root = std::env::temp_dir().join(format!("pathmap-ffi-snapshots-{nonce}"));
        fs::create_dir_all(&root).unwrap();
        let manager = SnapshotManager::open(root.join("repository")).unwrap();
        for (generation, sort) in [("one", "artifact"), ("two", "machine")] {
            let mut index = Index::default();
            let mut stats = BuildStats::default();
            index
                .ingest_algebra_line(
                    &format!(
                        "(: {generation}_ev (≞ (has_sort {generation}_ev computer taxonomic_kind {sort}) (stv 1.000 0.900)))"
                    ),
                    &mut stats,
                )
                .unwrap();
            let staged = root.join(format!("staged-{generation}"));
            index.save(&staged, stats).unwrap();
            manager.publish(generation, &staged).unwrap();
        }
        manager.switch("one").unwrap();
        let handle = format!("snapshot_{nonce}");
        execute(
            "open-snapshot",
            &format!("{handle}\t{}\t1", manager.root().display()),
        )
        .unwrap();
        let rows = query_rows(
            "query-algebra",
            &format!("{handle}\ttaxonomic_kind\tcomputer\tsort"),
        )
        .unwrap();
        assert_eq!(rows[0].feature, "artifact");
        execute("snapshot-switch", &format!("{handle}\ttwo")).unwrap();
        let rows = query_rows(
            "query-algebra",
            &format!("{handle}\ttaxonomic_kind\tcomputer\tsort"),
        )
        .unwrap();
        assert_eq!(rows[0].feature, "machine");
        assert_eq!(execute("cache-stats", &handle).unwrap(), "(cache-stats 0 1 0 1 1)");
        execute("close", &handle).unwrap();
        fs::remove_dir_all(root).unwrap();
    }
}
