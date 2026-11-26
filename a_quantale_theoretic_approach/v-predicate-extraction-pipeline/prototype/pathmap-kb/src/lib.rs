pub mod canonical_jsonl;
pub mod shard_format;

use canonical_jsonl::{CanonicalKind, visit_jsonl_file};
use memmap2::Mmap;
use pathmap::PathMap;
use pathmap::arena_compact::{ACTMmap, ArenaCompactTree};
use pathmap::paths_serialization::{deserialize_paths_with_auxdata, serialize_paths_with_auxdata};
use pathmap::zipper::{ZipperIteration, ZipperPath, ZipperValues};
use shard_format::{
    INDEX_METADATA_FILE, IndexMetadata, SHARD_FORMAT_VERSION, SHARD_METADATA_FILE, ShardDescriptor,
    ShardMetadata, file_metadata, map_metadata, validate_file, validate_map, write_json,
};
use std::cell::{Cell, RefCell};
use std::collections::{HashMap, hash_map::Entry};
use std::fs::{self, File};
use std::io::{self, BufRead, BufReader, BufWriter, Read, Write};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};

pub const PROPERTY: u8 = 0x10;
pub const PROPERTY_FACT: u8 = 0x00;
pub const PROPERTY_WORLD: u8 = 0x01;
pub const SORT: u8 = 0x20;
pub const OPERATION: u8 = 0x30;
pub const PREDICATE: u8 = 0x40;
pub const AXIOM: u8 = 0x50;
pub const PERSPECTIVE_DEFINITION: u8 = 0x60;
pub const SUBPERSPECTIVE: u8 = 0x61;
pub const PERSPECTIVE_MATCH: u8 = 0x62;
pub const CONTRACT_VERSION: &str = "v-predicate/1";
pub const INDEX_FORMAT_VERSION: &str = "pathmap-kb/3";

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct RecordValue {
    pub strength: u16,
    pub confidence: u16,
    pub payload_strength: u16,
    pub payload_confidence: u16,
    pub payload: u64,
    pub evidence: u64,
    pub payload_evidence: u64,
    pub provenance: u64,
    pub payload_provenance: u64,
    pub world_perspective: u64,
    pub origin: u8,
    pub payload_origin: u8,
}

impl RecordValue {
    const SIZE: usize = 64;

    fn bytes(self) -> [u8; Self::SIZE] {
        let mut out = [0; Self::SIZE];
        out[0..2].copy_from_slice(&self.strength.to_le_bytes());
        out[2..4].copy_from_slice(&self.confidence.to_le_bytes());
        out[4..6].copy_from_slice(&self.payload_strength.to_le_bytes());
        out[6..8].copy_from_slice(&self.payload_confidence.to_le_bytes());
        out[8..16].copy_from_slice(&self.payload.to_le_bytes());
        out[16..24].copy_from_slice(&self.evidence.to_le_bytes());
        out[24..32].copy_from_slice(&self.payload_evidence.to_le_bytes());
        out[32..40].copy_from_slice(&self.provenance.to_le_bytes());
        out[40..48].copy_from_slice(&self.payload_provenance.to_le_bytes());
        out[48..56].copy_from_slice(&self.world_perspective.to_le_bytes());
        out[56] = self.origin;
        out[57] = self.payload_origin;
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
            provenance: u64::from_le_bytes(bytes[32..40].try_into().unwrap()),
            payload_provenance: u64::from_le_bytes(bytes[40..48].try_into().unwrap()),
            world_perspective: u64::from_le_bytes(bytes[48..56].try_into().unwrap()),
            origin: bytes[56],
            payload_origin: bytes[57],
        }
    }
}

#[derive(Default)]
pub struct Shard {
    pub primary: PathMap<RecordValue>,
    pub property_name: PathMap<RecordValue>,
    pub perspectives: PathMap<RecordValue>,
}

struct MappedMap {
    tree: ACTMmap,
    values: Mmap,
}

impl MappedMap {
    fn open(directory: &Path, metadata: &shard_format::MapMetadata) -> io::Result<Self> {
        let tree = ArenaCompactTree::open_mmap(directory.join(&metadata.act_file))?;
        let file = File::open(directory.join(&metadata.act_values_file))?;
        // SAFETY: immutable index snapshots are never modified in place; publication creates a new
        // directory. The mapping remains owned by this object for every borrowed value.
        let values = unsafe { Mmap::map(&file)? };
        if values.len() % RecordValue::SIZE != 0 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("{} has a truncated ACT values file", metadata.name),
            ));
        }
        Ok(Self { tree, values })
    }

    fn value(&self, index: u64) -> io::Result<RecordValue> {
        let offset = usize::try_from(index)
            .ok()
            .and_then(|index| index.checked_mul(RecordValue::SIZE))
            .ok_or_else(|| {
                io::Error::new(io::ErrorKind::InvalidData, "ACT value index overflow")
            })?;
        let bytes = self
            .values
            .get(offset..offset + RecordValue::SIZE)
            .ok_or_else(|| {
                io::Error::new(io::ErrorKind::InvalidData, "ACT value index out of range")
            })?;
        Ok(RecordValue::from_bytes(bytes))
    }

    fn rows_at(
        &self,
        prefix: &[u8],
        mut decode: impl FnMut(&[u8], RecordValue) -> ResultRow,
    ) -> io::Result<Vec<ResultRow>> {
        let mut zipper = self.tree.read_zipper_at_path_u64(prefix);
        let mut rows = Vec::new();
        while zipper.to_next_val() {
            let value = self.value(*zipper.val().unwrap())?;
            rows.push(decode(zipper.path(), value));
        }
        Ok(rows)
    }
}

/// One immutable perspective shard backed by memory-mapped ACT and value files.
pub struct MappedShardIndex {
    perspective: String,
    primary: MappedMap,
    property_name: MappedMap,
    perspectives: MappedMap,
    symbols: Arc<HashMap<u64, String>>,
    payloads: Arc<HashMap<u64, String>>,
}

/// Thread-safe ownership handle for one mapped shard. PathMap's mmap reader uses internal
/// cursors, so queries on the same shard are serialized while different shards remain independent.
pub type MappedShardHandle = Arc<Mutex<MappedShardIndex>>;

/// Opens index metadata and dictionaries only; perspective files are mapped by [`Self::load`].
pub struct ImmutableShardStore {
    root: PathBuf,
    metadata: IndexMetadata,
    by_perspective: HashMap<String, ShardDescriptor>,
    symbols: Arc<HashMap<u64, String>>,
    payloads: Arc<HashMap<u64, String>>,
    cache: Mutex<ShardCache>,
}

struct CachedShard {
    shard: MappedShardHandle,
    last_used: u64,
}

struct ShardCache {
    capacity: usize,
    clock: u64,
    hits: u64,
    loads: u64,
    evictions: u64,
    entries: HashMap<String, CachedShard>,
}

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct ShardCacheStats {
    pub hits: u64,
    pub loads: u64,
    pub evictions: u64,
    pub resident: usize,
    pub capacity: usize,
}

impl ImmutableShardStore {
    pub fn open(root: impl Into<PathBuf>) -> io::Result<Self> {
        Self::open_with_capacity(root, 8)
    }

    pub fn open_with_capacity(root: impl Into<PathBuf>, cache_capacity: usize) -> io::Result<Self> {
        if cache_capacity == 0 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "immutable shard cache capacity must be positive",
            ));
        }
        let root = root.into();
        validate_index_version(&root)?;
        let metadata: IndexMetadata = shard_format::read_json(&root.join(INDEX_METADATA_FILE))?;
        if metadata.format_version != INDEX_FORMAT_VERSION
            || metadata.contract_version != CONTRACT_VERSION
            || metadata.shard_format_version != SHARD_FORMAT_VERSION
            || metadata.record_value_size != RecordValue::SIZE
            || metadata.shard_count != metadata.shards.len()
        {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "incompatible immutable index metadata",
            ));
        }
        validate_file(&root, &metadata.symbols)?;
        validate_file(&root, &metadata.payloads)?;
        let mut by_perspective = HashMap::with_capacity(metadata.shards.len());
        for descriptor in &metadata.shards {
            if descriptor.perspective_id != format!("{:016x}", stable_id(&descriptor.perspective)) {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!("perspective ID mismatch for {}", descriptor.perspective),
                ));
            }
            if by_perspective
                .insert(descriptor.perspective.clone(), descriptor.clone())
                .is_some()
            {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!("duplicate perspective metadata: {}", descriptor.perspective),
                ));
            }
        }
        Ok(Self {
            symbols: Arc::new(read_dictionary(root.join("symbols.tsv"))?),
            payloads: Arc::new(read_dictionary(root.join("payloads.tsv"))?),
            root,
            metadata,
            by_perspective,
            cache: Mutex::new(ShardCache {
                capacity: cache_capacity,
                clock: 0,
                hits: 0,
                loads: 0,
                evictions: 0,
                entries: HashMap::new(),
            }),
        })
    }

    pub fn available_perspectives(&self) -> impl Iterator<Item = &str> {
        self.metadata
            .shards
            .iter()
            .map(|descriptor| descriptor.perspective.as_str())
    }

    pub fn load(&self, perspective: &str) -> io::Result<MappedShardHandle> {
        {
            let mut cache = self
                .cache
                .lock()
                .map_err(|_| io::Error::other("immutable shard cache lock is poisoned"))?;
            cache.clock += 1;
            let now = cache.clock;
            if let Some(entry) = cache.entries.get_mut(perspective) {
                entry.last_used = now;
                let shard = Arc::clone(&entry.shard);
                cache.hits += 1;
                return Ok(shard);
            }
        }

        let shard = Arc::new(Mutex::new(self.load_uncached(perspective)?));
        let mut cache = self
            .cache
            .lock()
            .map_err(|_| io::Error::other("immutable shard cache lock is poisoned"))?;
        cache.loads += 1;
        if cache.entries.len() == cache.capacity {
            let oldest = cache
                .entries
                .iter()
                .min_by_key(|(_, entry)| entry.last_used)
                .map(|(perspective, _)| perspective.clone())
                .expect("a full positive-capacity cache has an entry");
            cache.entries.remove(&oldest);
            cache.evictions += 1;
        }
        let now = cache.clock;
        cache.entries.insert(
            perspective.to_owned(),
            CachedShard {
                shard: Arc::clone(&shard),
                last_used: now,
            },
        );
        Ok(shard)
    }

    pub fn cache_stats(&self) -> ShardCacheStats {
        let cache = self
            .cache
            .lock()
            .expect("immutable shard cache lock is poisoned");
        ShardCacheStats {
            hits: cache.hits,
            loads: cache.loads,
            evictions: cache.evictions,
            resident: cache.entries.len(),
            capacity: cache.capacity,
        }
    }

    pub fn cached_perspectives(&self) -> Vec<String> {
        let cache = self
            .cache
            .lock()
            .expect("immutable shard cache lock is poisoned");
        let mut perspectives: Vec<_> = cache.entries.keys().cloned().collect();
        perspectives.sort();
        perspectives
    }

    fn load_uncached(&self, perspective: &str) -> io::Result<MappedShardIndex> {
        let descriptor = self.by_perspective.get(perspective).ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::NotFound,
                format!("no immutable shard for {perspective}"),
            )
        })?;
        let directory = self.root.join(&descriptor.directory);
        let expected_directory = format!("shards/{}", descriptor.perspective_id);
        if descriptor.directory != expected_directory
            || descriptor.metadata_file != SHARD_METADATA_FILE
        {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("unsafe shard location for {perspective}"),
            ));
        }
        let metadata: ShardMetadata =
            shard_format::read_json(&directory.join(&descriptor.metadata_file))?;
        if metadata.format_version != SHARD_FORMAT_VERSION
            || metadata.perspective != perspective
            || metadata.perspective_id != descriptor.perspective_id
        {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("incompatible shard metadata for {perspective}"),
            ));
        }
        if metadata.maps.len() != 3 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("shard {perspective} must contain exactly three maps"),
            ));
        }
        for name in ["primary", "property-name", "perspectives"] {
            let maps: Vec<_> = metadata
                .maps
                .iter()
                .filter(|map| map.name == name)
                .collect();
            if maps.len() != 1 {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!("shard {perspective} requires exactly one {name} map"),
                ));
            }
            validate_map(&directory, maps[0], RecordValue::SIZE)?;
        }
        let open_map = |name: &str| {
            let map = metadata
                .maps
                .iter()
                .find(|map| map.name == name)
                .ok_or_else(|| {
                    io::Error::new(io::ErrorKind::InvalidData, format!("missing {name} map"))
                })?;
            MappedMap::open(&directory, map)
        };
        Ok(MappedShardIndex {
            perspective: perspective.to_owned(),
            primary: open_map("primary")?,
            property_name: open_map("property-name")?,
            perspectives: open_map("perspectives")?,
            symbols: Arc::clone(&self.symbols),
            payloads: Arc::clone(&self.payloads),
        })
    }
}

impl MappedShardIndex {
    pub fn perspective(&self) -> &str {
        &self.perspective
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

    fn require_perspective(&self, perspective: &str) -> io::Result<()> {
        if self.perspective == perspective {
            Ok(())
        } else {
            Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                format!(
                    "loaded shard is {}, query requested {perspective}",
                    self.perspective
                ),
            ))
        }
    }

    pub fn query_properties(&self, perspective: &str, concept: &str) -> io::Result<Vec<ResultRow>> {
        self.require_perspective(perspective)?;
        let mut prefix = Vec::with_capacity(9);
        push_id(&mut prefix, stable_id(concept));
        prefix.push(PROPERTY);
        Ok(self
            .primary
            .rows_at(&prefix, |key, value| ResultRow {
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
                evaluation_perspective: None,
                provenance: self.payload(value.provenance),
                origin: origin_name(value.origin),
                payload_provenance: None,
                payload_origin: None,
            })?
            .into_iter()
            .filter(|row| row.world.is_none())
            .collect())
    }

    pub fn query_worlds(
        &self,
        perspective: &str,
        concept: &str,
        property: &str,
    ) -> io::Result<Vec<ResultRow>> {
        self.require_perspective(perspective)?;
        let mut prefix = Vec::with_capacity(18);
        push_id(&mut prefix, stable_id(concept));
        prefix.push(PROPERTY);
        push_id(&mut prefix, stable_id(property));
        prefix.push(PROPERTY_WORLD);
        self.primary.rows_at(&prefix, |key, value| ResultRow {
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
            evaluation_perspective: (value.world_perspective != 0)
                .then(|| self.symbol(value.world_perspective)),
            provenance: self.payload(value.provenance),
            origin: origin_name(value.origin),
            payload_provenance: None,
            payload_origin: None,
        })
    }

    pub fn query_property_name(&self, property: &str) -> io::Result<Vec<ResultRow>> {
        let mut prefix = Vec::with_capacity(8);
        push_id(&mut prefix, stable_id(property));
        self.property_name.rows_at(&prefix, |key, value| ResultRow {
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
            evaluation_perspective: (value.world_perspective != 0)
                .then(|| self.symbol(value.world_perspective)),
            provenance: self.payload(value.provenance),
            origin: origin_name(value.origin),
            payload_provenance: None,
            payload_origin: None,
        })
    }

    pub fn query_algebra(&self, concept: &str, family: &str) -> io::Result<Vec<ResultRow>> {
        let tag = match family {
            "sort" => SORT,
            "operation" => OPERATION,
            "predicate" => PREDICATE,
            "axiom" => AXIOM,
            _ => return Ok(vec![]),
        };
        let mut prefix = Vec::with_capacity(9);
        push_id(&mut prefix, stable_id(concept));
        prefix.push(tag);
        self.primary.rows_at(&prefix, |key, value| {
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
                evaluation_perspective: None,
                provenance: self.payload(value.provenance),
                origin: origin_name(value.origin),
                payload_provenance: self.payload(value.payload_provenance),
                payload_origin: origin_name(value.payload_origin),
            }
        })
    }

    pub fn query_perspective_relations(&self, family: &str) -> io::Result<Vec<ResultRow>> {
        let (tag, family) = match family {
            "definition" => (PERSPECTIVE_DEFINITION, "perspective-definition"),
            "subperspective" => (SUBPERSPECTIVE, "subperspective"),
            "match" => (PERSPECTIVE_MATCH, "perspective-match"),
            _ => return Ok(vec![]),
        };
        self.perspectives.rows_at(&[tag], |key, value| ResultRow {
            concept: self.perspective.clone(),
            family,
            feature: self.symbol(id_at(key, 0)),
            world: None,
            payload: (tag == PERSPECTIVE_MATCH).then(|| self.symbol(id_at(key, 8))),
            evidence: self.symbol(value.evidence),
            strength: value.strength as f32 / 1000.0,
            confidence: value.confidence as f32 / 1000.0,
            payload_strength: None,
            payload_confidence: None,
            payload_evidence: None,
            evaluation_perspective: None,
            provenance: self.payload(value.provenance),
            origin: origin_name(value.origin),
            payload_provenance: None,
            payload_origin: None,
        })
    }

    pub fn build_specification(&self, concept: &str) -> io::Result<Vec<ResultRow>> {
        let properties = self.query_properties(&self.perspective, concept)?;
        let mut rows = Vec::new();
        for family in ["sort", "operation", "predicate", "axiom"] {
            rows.extend(self.query_algebra(concept, family)?);
        }
        for property in &properties {
            rows.extend(self.query_worlds(&self.perspective, concept, &property.feature)?);
        }
        rows.extend(properties);
        Ok(rows)
    }
}

#[derive(Default)]
pub struct Index {
    pub shards: HashMap<u64, Shard>,
    pub symbols: HashMap<u64, String>,
    pub payloads: HashMap<u64, String>,
    property_refs: HashMap<String, PropertyRef>,
    operations: HashMap<String, OperationRef>,
    predicates: HashMap<String, OperationRef>,
    provenance: HashMap<String, ProvenanceRef>,
    perspective_records: HashMap<String, u64>,
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

#[derive(Clone, Copy)]
struct ProvenanceRef {
    payload: u64,
    origin: u8,
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
    pub perspective_definitions: u64,
    pub subperspectives: u64,
    pub perspective_matches: u64,
    pub provenance_records: u64,
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
    pub evaluation_perspective: Option<String>,
    pub provenance: Option<String>,
    pub origin: Option<&'static str>,
    pub payload_provenance: Option<String>,
    pub payload_origin: Option<&'static str>,
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

fn origin_code(origin: &str) -> Option<u8> {
    match origin {
        "asserted" => Some(1),
        "inferred" => Some(2),
        "generated" => Some(3),
        _ => None,
    }
}

fn origin_name(origin: u8) -> Option<&'static str> {
    match origin {
        1 => Some("asserted"),
        2 => Some("inferred"),
        3 => Some("generated"),
        _ => None,
    }
}

fn for_each_line(path: &Path, mut visit: impl FnMut(&str) -> io::Result<()>) -> io::Result<()> {
    let reader = BufReader::with_capacity(1024 * 1024, File::open(path)?);
    for line in reader.lines() {
        visit(&line?)?;
    }
    Ok(())
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
        let provenance = self.provenance.get(evidence).copied();
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
            provenance: provenance.map_or(0, |record| record.payload),
            origin: provenance.map_or(0, |record| record.origin),
            ..RecordValue::default()
        })
    }

    fn ingest_provenance_line(&mut self, line: &str, stats: &mut BuildStats) -> io::Result<bool> {
        let Some(arguments) = list_args(line, "evidence_provenance") else {
            return Ok(false);
        };
        if arguments.len() != 8 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "evidence_provenance requires eight arguments",
            ));
        }
        let origin = origin_code(&arguments[7]).ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::InvalidData,
                format!("unknown fact origin: {}", arguments[7]),
            )
        })?;
        let expression = format!("(evidence_provenance {})", arguments.join(" "));
        let payload = self.intern_payload(&expression)?;
        match self
            .provenance
            .insert(arguments[0].clone(), ProvenanceRef { payload, origin })
        {
            Some(previous) if previous.payload != payload || previous.origin != origin => {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!("conflicting provenance for {}", arguments[0]),
                ));
            }
            Some(_) => return Ok(true),
            None => {}
        }
        stats.provenance_records += 1;
        Ok(true)
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
            let reference = self.property_refs.get(&a[1]).cloned().ok_or_else(|| {
                io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!("property world references missing property: {}", a[1]),
                )
            })?;
            let evidence = self.intern_symbol(&a[0])?;
            let evaluation_perspective = self.intern_symbol(&a[2])?;
            let world = self.intern_symbol(&a[3])?;
            let mut value = self.value(line, &a[0], None)?;
            value.world_perspective = evaluation_perspective;
            let mut primary = Vec::with_capacity(34);
            push_id(&mut primary, reference.concept);
            primary.push(PROPERTY);
            push_id(&mut primary, reference.property);
            primary.push(PROPERTY_WORLD);
            push_id(&mut primary, world);
            push_id(&mut primary, evidence);
            self.shards
                .entry(reference.perspective)
                .or_default()
                .primary
                .insert(primary, value);

            let mut inverted = Vec::with_capacity(32);
            push_id(&mut inverted, reference.property);
            push_id(&mut inverted, world);
            push_id(&mut inverted, reference.concept);
            push_id(&mut inverted, evidence);
            self.shards
                .entry(evaluation_perspective)
                .or_default()
                .property_name
                .insert(inverted, value);
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
            self.insert_algebra(
                op.perspective,
                op.concept,
                OPERATION,
                op.operation,
                op.evidence,
                op.value,
            );
            self.operations.insert(a[0].clone(), op);
            stats.operations += 1;
            return Ok(true);
        }
        if let Some(a) = list_args(line, "operation_signature") {
            if a.len() != 2 {
                return Ok(false);
            }
            let op = self.operations.get(&a[0]).cloned().ok_or_else(|| {
                io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!("operation signature references missing edge: {}", a[0]),
                )
            })?;
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
            let signature_evidence = outer_evidence(line).unwrap_or(&a[0]);
            value.payload_evidence = self.intern_symbol(signature_evidence)?;
            if let Some(provenance) = self.provenance.get(signature_evidence) {
                value.payload_provenance = provenance.payload;
                value.payload_origin = provenance.origin;
            }
            self.insert_algebra(
                op.perspective,
                op.concept,
                OPERATION,
                op.operation,
                op.evidence,
                value,
            );
            return Ok(true);
        }
        if let Some(a) = list_args(line, "predicate_signature") {
            if a.len() != 2 {
                return Ok(false);
            }
            let predicate = self.predicates.get(&a[0]).cloned().ok_or_else(|| {
                io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!("predicate signature references missing edge: {}", a[0]),
                )
            })?;
            let mut value = predicate.value;
            value.payload = self.intern_payload(&a[1])?;
            let (strength, confidence) = tv(line).ok_or_else(|| {
                io::Error::new(
                    io::ErrorKind::InvalidData,
                    "missing predicate-signature stv",
                )
            })?;
            value.payload_strength = strength;
            value.payload_confidence = confidence;
            let signature_evidence = outer_evidence(line).unwrap_or(&a[0]);
            value.payload_evidence = self.intern_symbol(signature_evidence)?;
            if let Some(provenance) = self.provenance.get(signature_evidence) {
                value.payload_provenance = provenance.payload;
                value.payload_origin = provenance.origin;
            }
            self.insert_algebra(
                predicate.perspective,
                predicate.concept,
                PREDICATE,
                predicate.operation,
                predicate.evidence,
                value,
            );
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
                let value = self.value(line, &a[0], None)?;
                self.insert_algebra(perspective, concept, tag, feature, evidence, value);
                if tag == PREDICATE {
                    self.predicates.insert(
                        a[0].clone(),
                        OperationRef {
                            perspective,
                            concept,
                            operation: feature,
                            evidence,
                            value,
                        },
                    );
                }
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

    pub fn ingest_perspective_line(
        &mut self,
        line: &str,
        stats: &mut BuildStats,
    ) -> io::Result<bool> {
        let (predicate, tag, count) = if line.contains("(classified_perspective ") {
            ("classified_perspective", PERSPECTIVE_DEFINITION, 2)
        } else if line.contains("(subperspective ") {
            ("subperspective", SUBPERSPECTIVE, 2)
        } else if line.contains("(perspective_match ") {
            ("perspective_match", PERSPECTIVE_MATCH, 3)
        } else {
            return Ok(false);
        };
        let arguments = list_args(line, predicate).ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::InvalidData,
                format!("invalid {predicate} record"),
            )
        })?;
        if arguments.len() != count {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("{predicate} requires {count} arguments"),
            ));
        }
        let shard_perspective = self.intern_symbol(&arguments[0])?;
        let evidence_name = outer_evidence(line).ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::InvalidData,
                "missing outer evidence identifier",
            )
        })?;
        let relation_id = stable_id(&format!("{predicate}\u{1f}{}", arguments.join("\u{1f}")));
        match self
            .perspective_records
            .insert(evidence_name.to_owned(), relation_id)
        {
            Some(previous) if previous != relation_id => {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!("conflicting perspective record for {evidence_name}"),
                ));
            }
            Some(_) => return Ok(true),
            None => {}
        }
        let evidence = self.intern_symbol(evidence_name)?;
        let mut key = Vec::with_capacity(25);
        key.push(tag);
        for argument in &arguments[1..] {
            push_id(&mut key, self.intern_symbol(argument)?);
        }
        push_id(&mut key, evidence);
        let value = self.value(line, evidence_name, None)?;
        self.shards
            .entry(shard_perspective)
            .or_default()
            .perspectives
            .insert(key, value);
        match tag {
            PERSPECTIVE_DEFINITION => stats.perspective_definitions += 1,
            SUBPERSPECTIVE => stats.subperspectives += 1,
            PERSPECTIVE_MATCH => stats.perspective_matches += 1,
            _ => unreachable!(),
        }
        Ok(true)
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
        // Collect provenance before materializing values, regardless of source ordering.
        for_each_line(path, |line| {
            self.ingest_provenance_line(line, stats)?;
            Ok(())
        })?;
        for_each_line(path, |line| {
            self.ingest_perspective_line(line, stats)?;
            Ok(())
        })?;

        if property_kb {
            for_each_line(path, |line| {
                if !line.contains("(has_scoped_property ") {
                    return Ok(());
                }
                if limit_per_kind.is_some_and(|limit| stats.property_facts >= limit) {
                    return Ok(());
                }
                self.ingest_property_line(line, stats)?;
                Ok(())
            })?;
            for_each_line(path, |line| {
                if !line.contains("(scoped_property_holds_in ") {
                    return Ok(());
                }
                if limit_per_kind.is_some_and(|limit| stats.world_facts >= limit) {
                    return Ok(());
                }
                let property_id = list_args(line, "scoped_property_holds_in")
                    .and_then(|arguments| arguments.get(1).cloned());
                if limit_per_kind.is_some()
                    && property_id
                        .as_ref()
                        .is_some_and(|id| !self.property_refs.contains_key(id))
                {
                    stats.skipped_worlds += 1;
                    return Ok(());
                }
                self.ingest_property_line(line, stats)?;
                Ok(())
            })?;
            return Ok(());
        }

        for_each_line(path, |line| {
            if (line.contains("(has_sort ")
                && limit_per_kind.is_some_and(|limit| stats.sorts >= limit))
                || (line.contains("(has_operation ")
                    && limit_per_kind.is_some_and(|limit| stats.operations >= limit))
                || (line.contains("(has_predicate ")
                    && limit_per_kind.is_some_and(|limit| stats.predicates >= limit))
                || (line.contains("(has_axiom ")
                    && limit_per_kind.is_some_and(|limit| stats.axioms >= limit))
            {
                return Ok(());
            }
            if line.contains("(has_sort ")
                || line.contains("(has_operation ")
                || line.contains("(has_predicate ")
                || line.contains("(has_axiom ")
            {
                self.ingest_algebra_line(line, stats)?;
            }
            Ok(())
        })?;
        for_each_line(path, |line| {
            if line.contains("(operation_signature ") {
                let edge = list_args(line, "operation_signature")
                    .and_then(|arguments| arguments.first().cloned());
                if limit_per_kind.is_some()
                    && edge
                        .as_ref()
                        .is_some_and(|id| !self.operations.contains_key(id))
                {
                    return Ok(());
                }
                self.ingest_algebra_line(line, stats)?;
            } else if line.contains("(predicate_signature ") {
                let edge = list_args(line, "predicate_signature")
                    .and_then(|arguments| arguments.first().cloned());
                if limit_per_kind.is_some()
                    && edge
                        .as_ref()
                        .is_some_and(|id| !self.predicates.contains_key(id))
                {
                    return Ok(());
                }
                self.ingest_algebra_line(line, stats)?;
            }
            Ok(())
        })?;
        Ok(())
    }

    /// Compile canonical JSONL in bounded-memory passes.
    ///
    /// The passes deliberately mirror the reference resolution graph: provenance and perspective
    /// relations first, declarations second, and worlds/signatures last. Input order therefore has
    /// no effect on the resulting index, while no collection of source records is retained.
    pub fn ingest_canonical_jsonl(
        &mut self,
        path: &Path,
        stats: &mut BuildStats,
    ) -> io::Result<u64> {
        let records = visit_jsonl_file(path, |line_number, record| {
            let provenance = record.provenance_line()?;
            self.ingest_provenance_line(&provenance, stats)
                .map_err(|error| jsonl_ingest_error(line_number, error))?;
            if matches!(
                record.kind,
                CanonicalKind::ClassifiedPerspective
                    | CanonicalKind::Subperspective
                    | CanonicalKind::PerspectiveMatch
            ) {
                let fact = record.fact_line()?;
                self.ingest_perspective_line(&fact, stats)
                    .map_err(|error| jsonl_ingest_error(line_number, error))?;
            }
            Ok(())
        })?;

        visit_jsonl_file(path, |line_number, record| {
            let fact = record.fact_line()?;
            let result = match record.kind {
                CanonicalKind::HasScopedProperty => self.ingest_property_line(&fact, stats),
                CanonicalKind::HasSort
                | CanonicalKind::HasOperation
                | CanonicalKind::HasPredicate
                | CanonicalKind::HasAxiom => self.ingest_algebra_line(&fact, stats),
                _ => return Ok(()),
            };
            if !result.map_err(|error| jsonl_ingest_error(line_number, error))? {
                return Err(jsonl_ingest_error(
                    line_number,
                    io::Error::new(io::ErrorKind::InvalidData, "record was not indexed"),
                ));
            }
            Ok(())
        })?;

        visit_jsonl_file(path, |line_number, record| {
            let fact = record.fact_line()?;
            let result = match record.kind {
                CanonicalKind::ScopedPropertyHoldsIn => self.ingest_property_line(&fact, stats),
                CanonicalKind::OperationSignature | CanonicalKind::PredicateSignature => {
                    self.ingest_algebra_line(&fact, stats)
                }
                _ => return Ok(()),
            };
            if !result.map_err(|error| jsonl_ingest_error(line_number, error))? {
                return Err(jsonl_ingest_error(
                    line_number,
                    io::Error::new(io::ErrorKind::InvalidData, "record was not indexed"),
                ));
            }
            Ok(())
        })?;
        Ok(records)
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
            evaluation_perspective: None,
            provenance: self.payload(value.provenance),
            origin: origin_name(value.origin),
            payload_provenance: None,
            payload_origin: None,
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
            evaluation_perspective: (value.world_perspective != 0)
                .then(|| self.symbol(value.world_perspective)),
            provenance: self.payload(value.provenance),
            origin: origin_name(value.origin),
            payload_provenance: None,
            payload_origin: None,
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
            evaluation_perspective: (value.world_perspective != 0)
                .then(|| self.symbol(value.world_perspective)),
            provenance: self.payload(value.provenance),
            origin: origin_name(value.origin),
            payload_provenance: None,
            payload_origin: None,
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
                evaluation_perspective: None,
                provenance: self.payload(value.provenance),
                origin: origin_name(value.origin),
                payload_provenance: self.payload(value.payload_provenance),
                payload_origin: origin_name(value.payload_origin),
            }
        })
    }

    pub fn query_perspective_relations(&self, perspective: &str, family: &str) -> Vec<ResultRow> {
        let (tag, family) = match family {
            "definition" => (PERSPECTIVE_DEFINITION, "perspective-definition"),
            "subperspective" => (SUBPERSPECTIVE, "subperspective"),
            "match" => (PERSPECTIVE_MATCH, "perspective-match"),
            _ => return vec![],
        };
        let Some(shard) = self.shards.get(&stable_id(perspective)) else {
            return vec![];
        };
        self.rows_at(&shard.perspectives, &[tag], |key, value| ResultRow {
            concept: perspective.to_owned(),
            family,
            feature: self.symbol(id_at(key, 0)),
            world: None,
            payload: (tag == PERSPECTIVE_MATCH).then(|| self.symbol(id_at(key, 8))),
            evidence: self.symbol(value.evidence),
            strength: value.strength as f32 / 1000.0,
            confidence: value.confidence as f32 / 1000.0,
            payload_strength: None,
            payload_confidence: None,
            payload_evidence: None,
            evaluation_perspective: None,
            provenance: self.payload(value.provenance),
            origin: origin_name(value.origin),
            payload_provenance: None,
            payload_origin: None,
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
        fs::write(
            root.join("contract-version.txt"),
            format!("{CONTRACT_VERSION}\n"),
        )?;
        fs::write(
            root.join("index-format-version.txt"),
            format!("{INDEX_FORMAT_VERSION}\n"),
        )?;
        write_dictionary(root.join("symbols.tsv"), &self.symbols)?;
        write_dictionary(root.join("payloads.tsv"), &self.payloads)?;
        let mut manifest = BufWriter::new(File::create(root.join("manifest.tsv"))?);
        writeln!(
            manifest,
            "# perspective_id\tperspective\tprimary_paths\tproperty_name_paths\tperspective_paths"
        )?;
        let mut descriptors = Vec::with_capacity(self.shards.len());
        let mut shard_ids: Vec<_> = self.shards.keys().copied().collect();
        shard_ids.sort_unstable();
        for id in shard_ids {
            let name = format!("{id:016x}");
            let dir = root.join("shards").join(&name);
            fs::create_dir_all(&dir)?;
            let shard = &self.shards[&id];
            let primary_count = save_map(&shard.primary, &dir.join("primary"))?;
            let inverted_count = save_map(&shard.property_name, &dir.join("property-name"))?;
            let perspective_count = save_map(&shard.perspectives, &dir.join("perspectives"))?;
            let perspective = self.symbol(id);
            let metadata = ShardMetadata {
                format_version: SHARD_FORMAT_VERSION.to_owned(),
                perspective_id: name.clone(),
                perspective: perspective.clone(),
                maps: vec![
                    map_metadata(&dir, "primary", primary_count, RecordValue::SIZE)?,
                    map_metadata(&dir, "property-name", inverted_count, RecordValue::SIZE)?,
                    map_metadata(&dir, "perspectives", perspective_count, RecordValue::SIZE)?,
                ],
            };
            write_json(&dir.join(SHARD_METADATA_FILE), &metadata)?;
            descriptors.push(ShardDescriptor {
                perspective_id: name.clone(),
                perspective: perspective.clone(),
                directory: format!("shards/{name}"),
                metadata_file: SHARD_METADATA_FILE.to_owned(),
            });
            writeln!(
                manifest,
                "{id:016x}\t{}\t{primary_count}\t{inverted_count}\t{perspective_count}",
                perspective
            )?;
        }
        write_json(
            &root.join(INDEX_METADATA_FILE),
            &IndexMetadata {
                format_version: INDEX_FORMAT_VERSION.to_owned(),
                contract_version: CONTRACT_VERSION.to_owned(),
                shard_format_version: SHARD_FORMAT_VERSION.to_owned(),
                record_value_size: RecordValue::SIZE,
                shard_count: descriptors.len(),
                symbols: file_metadata(root, "symbols.tsv")?,
                payloads: file_metadata(root, "payloads.tsv")?,
                shards: descriptors,
            },
        )?;
        let mut summary = BufWriter::new(File::create(root.join("build-stats.txt"))?);
        writeln!(summary, "property_facts={}", stats.property_facts)?;
        writeln!(summary, "world_facts={}", stats.world_facts)?;
        writeln!(summary, "sorts={}", stats.sorts)?;
        writeln!(summary, "operations={}", stats.operations)?;
        writeln!(summary, "predicates={}", stats.predicates)?;
        writeln!(summary, "axioms={}", stats.axioms)?;
        writeln!(summary, "skipped_worlds={}", stats.skipped_worlds)?;
        writeln!(
            summary,
            "perspective_definitions={}",
            stats.perspective_definitions
        )?;
        writeln!(summary, "subperspectives={}", stats.subperspectives)?;
        writeln!(summary, "perspective_matches={}", stats.perspective_matches)?;
        writeln!(summary, "provenance_records={}", stats.provenance_records)?;
        Ok(())
    }

    pub fn load_shard(root: &Path, perspective: &str) -> io::Result<Self> {
        validate_index_version(root)?;
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
                perspectives: load_map(&dir.join("perspectives"))?,
            },
        );
        Ok(true)
    }
}

fn jsonl_ingest_error(line_number: u64, error: io::Error) -> io::Error {
    io::Error::new(
        error.kind(),
        format!("canonical JSONL line {line_number}: {error}"),
    )
}

fn validate_index_version(root: &Path) -> io::Result<()> {
    let contract = fs::read_to_string(root.join("contract-version.txt"))?;
    let format = fs::read_to_string(root.join("index-format-version.txt"))?;
    if contract.trim() != CONTRACT_VERSION || format.trim() != INDEX_FORMAT_VERSION {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            format!(
                "incompatible index: contract={} format={}",
                contract.trim(),
                format.trim()
            ),
        ));
    }
    Ok(())
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
    save_act_map(map, base)?;
    Ok(serialized.path_count)
}

fn save_act_map(map: &PathMap<RecordValue>, base: &Path) -> io::Result<()> {
    let next_index = Cell::new(0u64);
    let values = RefCell::new(BufWriter::new(File::create(
        base.with_extension("act-values"),
    )?));
    let tree = ArenaCompactTree::from_zipper(map.read_zipper(), |value| {
        let index = next_index.get();
        next_index.set(index + 1);
        values
            .borrow_mut()
            .write_all(&value.bytes())
            .expect("writing adjacent ACT values file");
        index
    });
    values.into_inner().flush()?;
    fs::write(base.with_extension("act"), tree.get_data())
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
    use std::time::{SystemTime, UNIX_EPOCH};

    const PROPERTY_LINE: &str = "(: property_ev (≞ (has_scoped_property property_ev computer functional_use property_key_computer_functional_use_process_information process_information) (stv 0.649 0.477)))";
    const WORLD_LINE: &str = "(: world_ev (≞ (scoped_property_holds_in world_ev property_key_computer_functional_use_process_information functional_use software) (stv 0.627 0.480)))";
    const OP_LINE: &str =
        "(: op_ev (≞ (has_operation op_ev computer functional_use process) (stv 0.649 0.697)))";
    const SIG_LINE: &str = "(: sig_ev (≞ (operation_signature op_ev (arrow computer information output)) (stv 0.900 0.860)))";

    const CROSS_WORLD_LINE: &str = "(: cross_world_ev (≞ (scoped_property_holds_in cross_world_ev property_key_computer_functional_use_process_information spatial_context workstation) (stv 0.700 0.800)))";

    fn temporary_file(name: &str, contents: &str) -> PathBuf {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let path = std::env::temp_dir().join(format!("pathmap-kb-{name}-{nonce}.metta"));
        fs::write(&path, contents).unwrap();
        path
    }

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
    fn cross_perspective_worlds_preserve_both_perspectives() {
        let mut index = Index::default();
        let mut stats = BuildStats::default();
        index
            .ingest_property_line(PROPERTY_LINE, &mut stats)
            .unwrap();
        index
            .ingest_property_line(CROSS_WORLD_LINE, &mut stats)
            .unwrap();

        let worlds = index.query_worlds("functional_use", "computer", "process_information");
        assert_eq!(worlds.len(), 1);
        assert_eq!(
            worlds[0].evaluation_perspective.as_deref(),
            Some("spatial_context")
        );
        assert_eq!(
            index
                .query_property_name("spatial_context", "process_information")
                .len(),
            1
        );
    }

    #[test]
    fn file_ingestion_is_order_independent_and_preserves_provenance() {
        let property_file = temporary_file(
            "property-order",
            &format!(
                "{CROSS_WORLD_LINE}\n{PROPERTY_LINE}\n(: property_ev_provenance (≞ (evidence_provenance property_ev wordnet \"computer.v.01\" \"nltk://wordnet\" \"3.1\" \"WordNet-3.0\" adapter asserted) (stv 1.000 1.000)))\n(: cross_world_ev_provenance (≞ (evidence_provenance cross_world_ev wordnet \"generated-world\" \"nltk://wordnet\" \"3.1\" \"WordNet-3.0\" heuristic generated) (stv 1.000 1.000)))\n"
            ),
        );
        let algebra_file = temporary_file(
            "algebra-order",
            &format!(
                "{SIG_LINE}\n{OP_LINE}\n(: op_ev_provenance (≞ (evidence_provenance op_ev wordnet \"operation\" \"nltk://wordnet\" \"3.1\" \"WordNet-3.0\" adapter asserted) (stv 1.000 1.000)))\n(: sig_ev_provenance (≞ (evidence_provenance sig_ev wordnet \"signature\" \"nltk://wordnet\" \"3.1\" \"WordNet-3.0\" adapter inferred) (stv 1.000 1.000)))\n"
            ),
        );
        let mut index = Index::default();
        let mut stats = BuildStats::default();
        index
            .ingest_file(&property_file, true, None, &mut stats)
            .unwrap();
        index
            .ingest_file(&algebra_file, false, None, &mut stats)
            .unwrap();
        fs::remove_file(property_file).unwrap();
        fs::remove_file(algebra_file).unwrap();

        let world = index.query_worlds("functional_use", "computer", "process_information");
        assert_eq!(world[0].origin, Some("generated"));
        assert!(
            world[0]
                .provenance
                .as_deref()
                .unwrap()
                .contains("generated-world")
        );
        let operation = index.query_algebra("functional_use", "computer", "operation");
        assert_eq!(operation[0].origin, Some("asserted"));
        assert_eq!(operation[0].payload_origin, Some("inferred"));
        assert!(
            operation[0]
                .payload_provenance
                .as_deref()
                .unwrap()
                .contains("signature")
        );
    }

    #[test]
    fn perspective_relations_are_indexed_with_provenance() {
        let definition = "(: perspective_ev (≞ (classified_perspective functional_use function_role) (stv 1.000 1.000)))";
        let provenance = "(: perspective_ev_provenance (≞ (evidence_provenance perspective_ev framework \"registry\" \"repository://contract\" \"1\" \"internal\" registry asserted) (stv 1.000 1.000)))";
        let mut index = Index::default();
        let mut stats = BuildStats::default();
        index
            .ingest_provenance_line(provenance, &mut stats)
            .unwrap();
        index
            .ingest_perspective_line(definition, &mut stats)
            .unwrap();
        let rows = index.query_perspective_relations("functional_use", "definition");
        assert_eq!(rows.len(), 1);
        assert_eq!(rows[0].feature, "function_role");
        assert_eq!(rows[0].origin, Some("asserted"));
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
