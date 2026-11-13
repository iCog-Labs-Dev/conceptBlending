use pathmap::PathMap;
use pathmap::paths_serialization::{deserialize_paths_with_auxdata, serialize_paths_with_auxdata};
use pathmap::zipper::{ZipperIteration, ZipperMoving, ZipperValues};
use std::collections::{HashMap, hash_map::Entry};
use std::fs::{self, File};
use std::io::{self, BufRead, BufReader, BufWriter, Read, Write};
use std::path::{Path, PathBuf};

pub const PROPERTY: u8 = 0x10;
pub const PROPERTY_FACT: u8 = 0x00;
pub const PROPERTY_WORLD: u8 = 0x01;
pub const SORT: u8 = 0x20;
pub const OPERATION: u8 = 0x30;
pub const PREDICATE: u8 = 0x40;
pub const AXIOM: u8 = 0x50;

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct RecordValue {
    pub strength: u16,
    pub confidence: u16,
    pub payload_strength: u16,
    pub payload_confidence: u16,
    pub payload: u64,
    pub evidence: u64,
    pub payload_evidence: u64,
}

impl RecordValue {
    const SIZE: usize = 32;

    fn bytes(self) -> [u8; Self::SIZE] {
        let mut out = [0; Self::SIZE];
        out[0..2].copy_from_slice(&self.strength.to_le_bytes());
        out[2..4].copy_from_slice(&self.confidence.to_le_bytes());
        out[4..6].copy_from_slice(&self.payload_strength.to_le_bytes());
        out[6..8].copy_from_slice(&self.payload_confidence.to_le_bytes());
        out[8..16].copy_from_slice(&self.payload.to_le_bytes());
        out[16..24].copy_from_slice(&self.evidence.to_le_bytes());
        out[24..32].copy_from_slice(&self.payload_evidence.to_le_bytes());
        out
    }

    fn from_bytes(bytes: &[u8]) -> Self {
        Self {
            strength: u16::from_le_bytes(bytes[0..2].try_into().unwrap()),
            confidence: u16::from_le_bytes(bytes[2..4].try_into().unwrap()),
            payload_strength: u16::from_le_bytes(bytes[4..6].try_into().unwrap()),
            payload_confidence: u16::from_le_bytes(bytes[6..8].try_into().unwrap()),
            payload: u64::from_le_bytes(bytes[8..16].try_into().unwrap()),
            evidence: u64::from_le_bytes(bytes[16..24].try_into().unwrap()),
            payload_evidence: u64::from_le_bytes(bytes[24..32].try_into().unwrap()),
        }
    }
}

#[derive(Default)]
pub struct Shard {
    pub primary: PathMap<RecordValue>,
    pub property_name: PathMap<RecordValue>,
}

#[derive(Default)]
pub struct Index {
    pub shards: HashMap<u64, Shard>,
    pub symbols: HashMap<u64, String>,
    pub payloads: HashMap<u64, String>,
    property_refs: HashMap<String, PropertyRef>,
    operations: HashMap<String, OperationRef>,
}

#[derive(Clone)]
struct PropertyRef {
    perspective: u64,
    concept: u64,
    property: u64,
}

#[derive(Clone)]
struct OperationRef {
    perspective: u64,
    concept: u64,
    operation: u64,
    evidence: u64,
    value: RecordValue,
}

#[derive(Default, Debug, Clone, Copy)]
pub struct BuildStats {
    pub property_facts: u64,
    pub world_facts: u64,
    pub sorts: u64,
    pub operations: u64,
    pub predicates: u64,
    pub axioms: u64,
    pub skipped_worlds: u64,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ResultRow {
    pub concept: String,
    pub family: &'static str,
    pub feature: String,
    pub world: Option<String>,
    pub payload: Option<String>,
    pub evidence: String,
    pub strength: f32,
    pub confidence: f32,
    pub payload_strength: Option<f32>,
    pub payload_confidence: Option<f32>,
    pub payload_evidence: Option<String>,
}

pub fn stable_id(text: &str) -> u64 {
    // FNV-1a is intentionally fixed here (rather than DefaultHasher) so IDs survive runs.
    let mut hash = 0xcbf29ce484222325u64;
    for byte in text.as_bytes() {
        hash ^= *byte as u64;
        hash = hash.wrapping_mul(0x100000001b3);
    }
    hash
}

fn push_id(key: &mut Vec<u8>, id: u64) {
    key.extend_from_slice(&id.to_be_bytes());
}

fn id_at(key: &[u8], offset: usize) -> u64 {
    u64::from_be_bytes(key[offset..offset + 8].try_into().unwrap())
}

fn tv(text: &str) -> Option<(u16, u16)> {
    let start = text.rfind("(stv ")? + 5;
    let rest = &text[start..];
    let mut values = rest.split(|c: char| c.is_ascii_whitespace() || c == ')');
    let strength = values.next()?.parse::<f64>().ok()?;
    let confidence = values.next()?.parse::<f64>().ok()?;
    Some((
        (strength * 1000.0).round() as u16,
        (confidence * 1000.0).round() as u16,
    ))
}

/// Return the top-level arguments of `(predicate ...)`, retaining nested expressions.
pub fn list_args(text: &str, predicate: &str) -> Option<Vec<String>> {
    let needle = format!("({predicate} ");
    let start = text.find(&needle)? + needle.len();
    let bytes = text.as_bytes();
    let mut args = Vec::new();
    let mut depth = 1i32;
    let mut token_start = None;
    let mut i = start;
    while i < bytes.len() {
        match bytes[i] {
            b'(' => {
                if token_start.is_none() {
                    token_start = Some(i);
                }
                depth += 1;
            }
            b')' => {
                depth -= 1;
                if depth == 0 {
                    if let Some(s) = token_start.take() {
                        args.push(text[s..i].trim().to_owned());
                    }
                    return Some(args);
                }
            }
            b' ' | b'\t' if depth == 1 => {
                if let Some(s) = token_start.take() {
                    args.push(text[s..i].to_owned());
                }
            }
            _ => {
                if token_start.is_none() {
                    token_start = Some(i);
                }
            }
        }
        i += 1;
    }
    None
}

fn outer_evidence(text: &str) -> Option<&str> {
    text.strip_prefix("(: ")?.split_ascii_whitespace().next()
}

impl Index {
    fn intern_symbol(&mut self, symbol: &str) -> io::Result<u64> {
        let id = stable_id(symbol);
        match self.symbols.entry(id) {
            Entry::Vacant(entry) => {
                entry.insert(symbol.to_owned());
            }
            Entry::Occupied(entry) if entry.get() != symbol => {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!("stable-ID collision: {:?} and {:?}", entry.get(), symbol),
                ));
            }
            Entry::Occupied(_) => {}
        }
        Ok(id)
    }

    fn intern_payload(&mut self, payload: &str) -> io::Result<u64> {
        let id = stable_id(payload);
        match self.payloads.entry(id) {
            Entry::Vacant(entry) => {
                entry.insert(payload.to_owned());
            }
            Entry::Occupied(entry) if entry.get() != payload => {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    "payload-ID collision",
                ));
            }
            Entry::Occupied(_) => {}
        }
        Ok(id)
    }

    fn value(
        &mut self,
        line: &str,
        evidence: &str,
        payload: Option<&str>,
    ) -> io::Result<RecordValue> {
        let (strength, confidence) = tv(line)
            .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "missing or invalid stv"))?;
        Ok(RecordValue {
            strength,
            confidence,
            payload_strength: 0,
            payload_confidence: 0,
            payload: match payload {
                Some(p) => self.intern_payload(p)?,
                None => 0,
            },
            evidence: self.intern_symbol(evidence)?,
            payload_evidence: 0,
        })
    }

    pub fn ingest_property_line(&mut self, line: &str, stats: &mut BuildStats) -> io::Result<bool> {
        if let Some(a) = list_args(line, "has_scoped_property") {
            if a.len() != 5 {
                return Ok(false);
            }
            let evidence = self.intern_symbol(&a[0])?;
            let concept = self.intern_symbol(&a[1])?;
            let perspective = self.intern_symbol(&a[2])?;
            let property = self.intern_symbol(&a[4])?;
            let value = self.value(line, &a[0], None)?;
            self.property_refs.insert(
                a[3].clone(),
                PropertyRef {
                    perspective,
                    concept,
                    property,
                },
            );
            let mut key = Vec::with_capacity(26);
            push_id(&mut key, concept);
            key.push(PROPERTY);
            push_id(&mut key, property);
            key.push(PROPERTY_FACT);
            push_id(&mut key, evidence);
            self.shards
                .entry(perspective)
                .or_default()
                .primary
                .insert(key, value);
            stats.property_facts += 1;
            return Ok(true);
        }
        if let Some(a) = list_args(line, "scoped_property_holds_in") {
            if a.len() != 4 {
                return Ok(false);
            }
            let Some(reference) = self.property_refs.get(&a[1]).cloned() else {
                stats.skipped_worlds += 1;
                return Ok(false);
            };
            let evidence = self.intern_symbol(&a[0])?;
            let stated_perspective = self.intern_symbol(&a[2])?;
            if stated_perspective != reference.perspective {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!("perspective mismatch for property ref {}", a[1]),
                ));
            }
            let world = self.intern_symbol(&a[3])?;
            let value = self.value(line, &a[0], None)?;
            let shard = self.shards.entry(reference.perspective).or_default();
            let mut primary = Vec::with_capacity(34);
            push_id(&mut primary, reference.concept);
            primary.push(PROPERTY);
            push_id(&mut primary, reference.property);
            primary.push(PROPERTY_WORLD);
            push_id(&mut primary, world);
            push_id(&mut primary, evidence);
            shard.primary.insert(primary, value);

            let mut inverted = Vec::with_capacity(32);
            push_id(&mut inverted, reference.property);
            push_id(&mut inverted, world);
            push_id(&mut inverted, reference.concept);
            push_id(&mut inverted, evidence);
            shard.property_name.insert(inverted, value);
            stats.world_facts += 1;
            return Ok(true);
        }
        Ok(false)
    }

    pub fn ingest_algebra_line(&mut self, line: &str, stats: &mut BuildStats) -> io::Result<bool> {
        if let Some(a) = list_args(line, "has_operation") {
            if a.len() != 4 {
                return Ok(false);
            }
            let perspective = self.intern_symbol(&a[2])?;
            let value = self.value(line, &a[0], None)?;
            let op = OperationRef {
                perspective,
                concept: self.intern_symbol(&a[1])?,
                operation: self.intern_symbol(&a[3])?,
                evidence: value.evidence,
                value,
            };
            self.operations.insert(a[0].clone(), op);
            return Ok(true);
        }
        if let Some(a) = list_args(line, "operation_signature") {
            if a.len() != 2 {
                return Ok(false);
            }
            let Some(op) = self.operations.get(&a[0]).cloned() else {
                return Ok(false);
            };
            let mut value = op.value;
            value.payload = self.intern_payload(&a[1])?;
            let (signature_strength, signature_confidence) = tv(line).ok_or_else(|| {
                io::Error::new(
                    io::ErrorKind::InvalidData,
                    "missing operation-signature stv",
                )
            })?;
            value.payload_strength = signature_strength;
            value.payload_confidence = signature_confidence;
            value.payload_evidence = self.intern_symbol(outer_evidence(line).unwrap_or(&a[0]))?;
            self.insert_algebra(
                op.perspective,
                op.concept,
                OPERATION,
                op.operation,
                op.evidence,
                value,
            );
            stats.operations += 1;
            return Ok(true);
        }
        for (predicate, tag) in [
            ("has_sort", SORT),
            ("has_predicate", PREDICATE),
            ("has_axiom", AXIOM),
        ] {
            if let Some(a) = list_args(line, predicate) {
                if a.len() != 4 {
                    return Ok(false);
                }
                let perspective = self.intern_symbol(&a[2])?;
                let concept = self.intern_symbol(&a[1])?;
                let evidence = self.intern_symbol(&a[0])?;
                let nested = a[3].starts_with('(');
                let feature = if nested {
                    self.intern_payload(&a[3])?
                } else {
                    self.intern_symbol(&a[3])?
                };
                let value = self.value(line, &a[0], nested.then_some(a[3].as_str()))?;
                self.insert_algebra(perspective, concept, tag, feature, evidence, value);
                match tag {
                    SORT => stats.sorts += 1,
                    PREDICATE => stats.predicates += 1,
                    AXIOM => stats.axioms += 1,
                    _ => {}
                }
                return Ok(true);
            }
        }
        Ok(false)
    }

    fn insert_algebra(
        &mut self,
        perspective: u64,
        concept: u64,
        tag: u8,
        feature: u64,
        evidence: u64,
        value: RecordValue,
    ) {
        let mut key = Vec::with_capacity(25);
        push_id(&mut key, concept);
        key.push(tag);
        push_id(&mut key, feature);
        push_id(&mut key, evidence);
        self.shards
            .entry(perspective)
            .or_default()
            .primary
            .insert(key, value);
    }

    pub fn ingest_file(
        &mut self,
        path: &Path,
        property_kb: bool,
        limit_per_kind: Option<u64>,
        stats: &mut BuildStats,
    ) -> io::Result<()> {
        let reader = BufReader::with_capacity(1024 * 1024, File::open(path)?);
        for line in reader.lines() {
            let line = line?;
            if property_kb {
                let is_property = line.contains("(has_scoped_property ");
                let is_world = line.contains("(scoped_property_holds_in ");
                if is_property && limit_per_kind.is_some_and(|n| stats.property_facts >= n) {
                    continue;
                }
                if is_world && limit_per_kind.is_some_and(|n| stats.world_facts >= n) {
                    continue;
                }
                self.ingest_property_line(&line, stats)?;
            } else {
                let capped = |count| limit_per_kind.is_some_and(|n| count >= n);
                if (line.contains("(has_sort ") && capped(stats.sorts))
                    || (line.contains("(operation_signature ") && capped(stats.operations))
                    || (line.contains("(has_predicate ") && capped(stats.predicates))
                    || (line.contains("(has_axiom ") && capped(stats.axioms))
                {
                    continue;
                }
                // Keep has_operation records until enough signatures have been resolved.
                if line.contains("(has_operation ") && capped(stats.operations) {
                    continue;
                }
                self.ingest_algebra_line(&line, stats)?;
            }
        }
        Ok(())
    }

    fn symbol(&self, id: u64) -> String {
        self.symbols
            .get(&id)
            .cloned()
            .unwrap_or_else(|| format!("#{id:016x}"))
    }

    fn payload(&self, id: u64) -> Option<String> {
        (id != 0).then(|| {
            self.payloads
                .get(&id)
                .cloned()
                .unwrap_or_else(|| format!("#{id:016x}"))
        })
    }

    fn rows_at(
        &self,
        map: &PathMap<RecordValue>,
        prefix: &[u8],
        decode: impl Fn(&[u8], &RecordValue) -> ResultRow,
    ) -> Vec<ResultRow> {
        let mut zipper = map.read_zipper_at_path(prefix);
        let mut rows = Vec::new();
        while zipper.to_next_val() {
            rows.push(decode(zipper.path(), zipper.val().unwrap()));
        }
        rows
    }

    pub fn query_properties(&self, perspective: &str, concept: &str) -> Vec<ResultRow> {
        let Some(shard) = self.shards.get(&stable_id(perspective)) else {
            return vec![];
        };
        let concept_id = stable_id(concept);
        let mut prefix = Vec::with_capacity(9);
        push_id(&mut prefix, concept_id);
        prefix.push(PROPERTY);
        self.rows_at(&shard.primary, &prefix, |key, value| ResultRow {
            concept: concept.to_owned(),
            family: "property",
            feature: self.symbol(id_at(key, 0)),
            world: (key.get(8) == Some(&PROPERTY_WORLD)).then(|| self.symbol(id_at(key, 9))),
            payload: None,
            evidence: self.symbol(value.evidence),
            strength: value.strength as f32 / 1000.0,
            confidence: value.confidence as f32 / 1000.0,
            payload_strength: None,
            payload_confidence: None,
            payload_evidence: None,
        })
        .into_iter()
        .filter(|row| row.world.is_none())
        .collect()
    }

    pub fn query_worlds(&self, perspective: &str, concept: &str, property: &str) -> Vec<ResultRow> {
        let Some(shard) = self.shards.get(&stable_id(perspective)) else {
            return vec![];
        };
        let mut prefix = Vec::with_capacity(18);
        push_id(&mut prefix, stable_id(concept));
        prefix.push(PROPERTY);
        push_id(&mut prefix, stable_id(property));
        prefix.push(PROPERTY_WORLD);
        self.rows_at(&shard.primary, &prefix, |key, value| ResultRow {
            concept: concept.to_owned(),
            family: "property-world",
            feature: property.to_owned(),
            world: Some(self.symbol(id_at(key, 0))),
            payload: None,
            evidence: self.symbol(value.evidence),
            strength: value.strength as f32 / 1000.0,
            confidence: value.confidence as f32 / 1000.0,
            payload_strength: None,
            payload_confidence: None,
            payload_evidence: None,
        })
    }

    pub fn query_property_name(&self, perspective: &str, property: &str) -> Vec<ResultRow> {
        let Some(shard) = self.shards.get(&stable_id(perspective)) else {
            return vec![];
        };
        let mut prefix = Vec::with_capacity(8);
        push_id(&mut prefix, stable_id(property));
        self.rows_at(&shard.property_name, &prefix, |key, value| ResultRow {
            concept: self.symbol(id_at(key, 8)),
            family: "property-name",
            feature: property.to_owned(),
            world: Some(self.symbol(id_at(key, 0))),
            payload: None,
            evidence: self.symbol(value.evidence),
            strength: value.strength as f32 / 1000.0,
            confidence: value.confidence as f32 / 1000.0,
            payload_strength: None,
            payload_confidence: None,
            payload_evidence: None,
        })
    }

    pub fn query_algebra(&self, perspective: &str, concept: &str, family: &str) -> Vec<ResultRow> {
        let tag = match family {
            "sort" => SORT,
            "operation" => OPERATION,
            "predicate" => PREDICATE,
            "axiom" => AXIOM,
            _ => return vec![],
        };
        let Some(shard) = self.shards.get(&stable_id(perspective)) else {
            return vec![];
        };
        let mut prefix = Vec::with_capacity(9);
        push_id(&mut prefix, stable_id(concept));
        prefix.push(tag);
        self.rows_at(&shard.primary, &prefix, |key, value| {
            let feature_id = id_at(key, 0);
            ResultRow {
                concept: concept.to_owned(),
                family: match tag {
                    SORT => "sort",
                    OPERATION => "operation",
                    PREDICATE => "predicate",
                    AXIOM => "axiom",
                    _ => unreachable!(),
                },
                feature: self
                    .symbols
                    .get(&feature_id)
                    .cloned()
                    .or_else(|| self.payloads.get(&feature_id).cloned())
                    .unwrap_or_else(|| format!("#{feature_id:016x}")),
                world: None,
                payload: self.payload(value.payload),
                evidence: self.symbol(value.evidence),
                strength: value.strength as f32 / 1000.0,
                confidence: value.confidence as f32 / 1000.0,
                payload_strength: (value.payload_strength != 0)
                    .then_some(value.payload_strength as f32 / 1000.0),
                payload_confidence: (value.payload_confidence != 0)
                    .then_some(value.payload_confidence as f32 / 1000.0),
                payload_evidence: (value.payload_evidence != 0)
                    .then(|| self.symbol(value.payload_evidence)),
            }
        })
    }

    /// Materialize the query-facing algebraic specification for one concept and perspective.
    pub fn build_specification(&self, perspective: &str, concept: &str) -> Vec<ResultRow> {
        let properties = self.query_properties(perspective, concept);
        let mut rows = Vec::new();
        for family in ["sort", "operation", "predicate", "axiom"] {
            rows.extend(self.query_algebra(perspective, concept, family));
        }
        for property in &properties {
            rows.extend(self.query_worlds(perspective, concept, &property.feature));
        }
        rows.extend(properties);
        rows
    }

    /// Insert a synthetic knowledge-source extension through the primary index path.
    pub fn extend_with_sorts(
        &mut self,
        perspective: &str,
        concept: &str,
        count: u64,
    ) -> io::Result<()> {
        let perspective = self.intern_symbol(perspective)?;
        let concept = self.intern_symbol(concept)?;
        for number in 1..=count {
            let sort = self.intern_symbol(&format!("extension_sort_{number}"))?;
            let evidence = self.intern_symbol(&format!("extension_evidence_{number}"))?;
            self.insert_algebra(
                perspective,
                concept,
                SORT,
                sort,
                evidence,
                RecordValue {
                    strength: 900,
                    confidence: 860,
                    evidence,
                    ..RecordValue::default()
                },
            );
        }
        Ok(())
    }

    pub fn save(&self, root: &Path, stats: BuildStats) -> io::Result<()> {
        fs::create_dir_all(root)?;
        write_dictionary(root.join("symbols.tsv"), &self.symbols)?;
        write_dictionary(root.join("payloads.tsv"), &self.payloads)?;
        let mut manifest = BufWriter::new(File::create(root.join("manifest.tsv"))?);
        writeln!(
            manifest,
            "# perspective_id\tperspective\tprimary_paths\tproperty_name_paths"
        )?;
        let mut shard_ids: Vec<_> = self.shards.keys().copied().collect();
        shard_ids.sort_unstable();
        for id in shard_ids {
            let name = format!("{id:016x}");
            let dir = root.join("shards").join(&name);
            fs::create_dir_all(&dir)?;
            let shard = &self.shards[&id];
            let primary_count = save_map(&shard.primary, &dir.join("primary"))?;
            let inverted_count = save_map(&shard.property_name, &dir.join("property-name"))?;
            writeln!(
                manifest,
                "{id:016x}\t{}\t{primary_count}\t{inverted_count}",
                self.symbol(id)
            )?;
        }
        let mut summary = BufWriter::new(File::create(root.join("build-stats.txt"))?);
        writeln!(summary, "property_facts={}", stats.property_facts)?;
        writeln!(summary, "world_facts={}", stats.world_facts)?;
        writeln!(summary, "sorts={}", stats.sorts)?;
        writeln!(summary, "operations={}", stats.operations)?;
        writeln!(summary, "predicates={}", stats.predicates)?;
        writeln!(summary, "axioms={}", stats.axioms)?;
        writeln!(summary, "skipped_worlds={}", stats.skipped_worlds)?;
        Ok(())
    }

    pub fn load_shard(root: &Path, perspective: &str) -> io::Result<Self> {
        let mut index = Self {
            symbols: read_dictionary(root.join("symbols.tsv"))?,
            payloads: read_dictionary(root.join("payloads.tsv"))?,
            ..Self::default()
        };
        index.load_perspective_shard(root, perspective)?;
        Ok(index)
    }

    /// Attach one perspective to an index whose shared symbol and payload dictionaries are
    /// already resident. Repeated calls for the same perspective are no-ops.
    pub fn load_perspective_shard(&mut self, root: &Path, perspective: &str) -> io::Result<bool> {
        let perspective_id = stable_id(perspective);
        if self.shards.contains_key(&perspective_id) {
            return Ok(false);
        }
        let dir = root.join("shards").join(format!("{perspective_id:016x}"));
        if !dir.exists() {
            return Err(io::Error::new(
                io::ErrorKind::NotFound,
                format!("no shard for {perspective}"),
            ));
        }
        self.shards.insert(
            perspective_id,
            Shard {
                primary: load_map(&dir.join("primary"))?,
                property_name: load_map(&dir.join("property-name"))?,
            },
        );
        Ok(true)
    }
}

fn write_dictionary(path: PathBuf, dictionary: &HashMap<u64, String>) -> io::Result<()> {
    let mut entries: Vec<_> = dictionary.iter().collect();
    entries.sort_unstable_by_key(|(id, _)| **id);
    let mut writer = BufWriter::new(File::create(path)?);
    for (id, text) in entries {
        writeln!(writer, "{id:016x}\t{text}")?;
    }
    Ok(())
}

fn read_dictionary(path: PathBuf) -> io::Result<HashMap<u64, String>> {
    let mut result = HashMap::new();
    for line in BufReader::new(File::open(path)?).lines() {
        let line = line?;
        let Some((id, text)) = line.split_once('\t') else {
            continue;
        };
        result.insert(
            u64::from_str_radix(id, 16)
                .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?,
            text.to_owned(),
        );
    }
    Ok(result)
}

fn save_map(map: &PathMap<RecordValue>, base: &Path) -> io::Result<usize> {
    let mut paths = BufWriter::new(File::create(base.with_extension("paths"))?);
    let mut values = BufWriter::new(File::create(base.with_extension("values"))?);
    let serialized = serialize_paths_with_auxdata(map.read_zipper(), &mut paths, |_, _, value| {
        values
            .write_all(&value.bytes())
            .expect("writing adjacent values file");
    })?;
    values.flush()?;
    Ok(serialized.path_count)
}

fn load_map(base: &Path) -> io::Result<PathMap<RecordValue>> {
    let mut raw = Vec::new();
    File::open(base.with_extension("values"))?.read_to_end(&mut raw)?;
    if raw.len() % RecordValue::SIZE != 0 {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "truncated values file",
        ));
    }
    let values: Vec<_> = raw
        .chunks_exact(RecordValue::SIZE)
        .map(RecordValue::from_bytes)
        .collect();
    let mut map = PathMap::new();
    let paths = BufReader::new(File::open(base.with_extension("paths"))?);
    let stats =
        deserialize_paths_with_auxdata(map.write_zipper(), paths, |index, _| values[index])?;
    if stats.path_count != values.len() {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "path/value count mismatch",
        ));
    }
    Ok(map)
}

#[cfg(test)]
mod tests {
    use super::*;

    const PROPERTY_LINE: &str = "(: property_ev (≞ (has_scoped_property property_ev computer functional_use property_key_computer_functional_use_process_information process_information) (stv 0.649 0.477)))";
    const WORLD_LINE: &str = "(: world_ev (≞ (scoped_property_holds_in world_ev property_key_computer_functional_use_process_information functional_use software) (stv 0.627 0.480)))";
    const OP_LINE: &str =
        "(: op_ev (≞ (has_operation op_ev computer functional_use process) (stv 0.649 0.697)))";
    const SIG_LINE: &str = "(: sig_ev (≞ (operation_signature op_ev (arrow computer information output)) (stv 0.900 0.860)))";

    #[test]
    fn parses_nested_arguments() {
        assert_eq!(
            list_args(SIG_LINE, "operation_signature").unwrap(),
            vec!["op_ev", "(arrow computer information output)"]
        );
    }

    #[test]
    fn property_primary_and_inverted_queries_work() {
        let mut index = Index::default();
        let mut stats = BuildStats::default();
        index
            .ingest_property_line(PROPERTY_LINE, &mut stats)
            .unwrap();
        index.ingest_property_line(WORLD_LINE, &mut stats).unwrap();
        let properties = index.query_properties("functional_use", "computer");
        assert_eq!(properties.len(), 1);
        assert_eq!(properties[0].feature, "process_information");
        let worlds = index.query_worlds("functional_use", "computer", "process_information");
        assert_eq!(worlds.len(), 1);
        assert_eq!(worlds[0].world.as_deref(), Some("software"));
        let inverse = index.query_property_name("functional_use", "process_information");
        assert_eq!(inverse.len(), 1);
        assert_eq!(inverse[0].concept, "computer");
    }

    #[test]
    fn operation_and_signature_are_colocated() {
        let mut index = Index::default();
        let mut stats = BuildStats::default();
        index.ingest_algebra_line(OP_LINE, &mut stats).unwrap();
        index.ingest_algebra_line(SIG_LINE, &mut stats).unwrap();
        let rows = index.query_algebra("functional_use", "computer", "operation");
        assert_eq!(rows.len(), 1);
        assert_eq!(rows[0].feature, "process");
        assert_eq!(
            rows[0].payload.as_deref(),
            Some("(arrow computer information output)")
        );
        assert_eq!(rows[0].payload_strength, Some(0.9));
        assert_eq!(rows[0].payload_evidence.as_deref(), Some("sig_ev"));
    }

    #[test]
    fn loading_an_attached_perspective_is_a_no_op() {
        let mut index = Index::default();
        index
            .shards
            .insert(stable_id("functional_use"), Shard::default());

        assert!(
            !index
                .load_perspective_shard(Path::new("/path/that/does/not/exist"), "functional_use")
                .unwrap()
        );
    }
}
