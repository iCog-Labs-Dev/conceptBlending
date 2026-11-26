//! Atomic publication and selection of immutable PathMap index generations.

use crate::{CONTRACT_VERSION, INDEX_FORMAT_VERSION, ImmutableShardStore};
use serde::{Deserialize, Serialize};
use std::fs::{self, File};
use std::io::{self, BufWriter, Write};
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

pub const SNAPSHOT_FORMAT_VERSION: &str = "pathmap-snapshots/1";
const MANIFEST: &str = "snapshot.json";
const CURRENT: &str = "current";

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct SnapshotManifest {
    pub format_version: String,
    pub generation: String,
    pub contract_version: String,
    pub index_format_version: String,
    pub created_unix_ms: u128,
}

#[derive(Clone, Debug)]
pub struct SnapshotManager {
    root: PathBuf,
}

impl SnapshotManager {
    pub fn open(root: impl Into<PathBuf>) -> io::Result<Self> {
        let root = root.into();
        fs::create_dir_all(root.join("generations"))?;
        Ok(Self { root })
    }

    pub fn root(&self) -> &Path {
        &self.root
    }

    pub fn publish(&self, generation: &str, staged_index: &Path) -> io::Result<PathBuf> {
        validate_generation(generation)?;
        ImmutableShardStore::open(staged_index)?;
        let generations = self.root.join("generations");
        let destination = generations.join(generation);
        if destination.exists() {
            return Err(io::Error::new(
                io::ErrorKind::AlreadyExists,
                format!("snapshot generation already exists: {generation}"),
            ));
        }
        let temporary = generations.join(format!(".publish-{generation}-{}", std::process::id()));
        if temporary.exists() {
            return Err(io::Error::new(
                io::ErrorKind::AlreadyExists,
                format!("snapshot publication already in progress: {generation}"),
            ));
        }
        fs::create_dir(&temporary)?;
        let temporary_index = temporary.join("index");
        if let Err(error) = fs::rename(staged_index, &temporary_index) {
            let _ = fs::remove_dir(&temporary);
            return Err(error);
        }
        let manifest = SnapshotManifest {
            format_version: SNAPSHOT_FORMAT_VERSION.to_owned(),
            generation: generation.to_owned(),
            contract_version: CONTRACT_VERSION.to_owned(),
            index_format_version: INDEX_FORMAT_VERSION.to_owned(),
            created_unix_ms: SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .map_err(io::Error::other)?
                .as_millis(),
        };
        write_json_synced(&temporary.join(MANIFEST), &manifest)?;
        File::open(&temporary)?.sync_all()?;
        fs::rename(&temporary, &destination)?;
        File::open(&generations)?.sync_all()?;
        self.switch(generation)?;
        Ok(destination.join("index"))
    }

    pub fn switch(&self, generation: &str) -> io::Result<PathBuf> {
        self.validate(generation)?;
        let temporary = self
            .root
            .join(format!(".{CURRENT}.tmp-{}", std::process::id()));
        {
            let file = File::create(&temporary)?;
            let mut writer = BufWriter::new(file);
            writeln!(writer, "{generation}")?;
            writer.flush()?;
            writer.get_ref().sync_all()?;
        }
        fs::rename(&temporary, self.root.join(CURRENT))?;
        File::open(&self.root)?.sync_all()?;
        Ok(self.generation_index(generation))
    }

    pub fn current_generation(&self) -> io::Result<String> {
        let generation = fs::read_to_string(self.root.join(CURRENT))?;
        let generation = generation.trim();
        self.validate(generation)?;
        Ok(generation.to_owned())
    }

    pub fn current_index(&self) -> io::Result<PathBuf> {
        Ok(self.generation_index(&self.current_generation()?))
    }

    pub fn validate(&self, generation: &str) -> io::Result<SnapshotManifest> {
        validate_generation(generation)?;
        let directory = self.root.join("generations").join(generation);
        let manifest: SnapshotManifest =
            serde_json::from_reader(File::open(directory.join(MANIFEST))?).map_err(invalid_json)?;
        if manifest.format_version != SNAPSHOT_FORMAT_VERSION
            || manifest.generation != generation
            || manifest.contract_version != CONTRACT_VERSION
            || manifest.index_format_version != INDEX_FORMAT_VERSION
        {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("incompatible snapshot manifest: {generation}"),
            ));
        }
        ImmutableShardStore::open(directory.join("index"))?;
        Ok(manifest)
    }

    fn generation_index(&self, generation: &str) -> PathBuf {
        self.root.join("generations").join(generation).join("index")
    }
}

fn validate_generation(generation: &str) -> io::Result<()> {
    if generation.is_empty()
        || generation == "."
        || generation == ".."
        || !generation
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'-' | b'_' | b'.'))
    {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            format!("unsafe snapshot generation: {generation:?}"),
        ));
    }
    Ok(())
}

fn write_json_synced(path: &Path, value: &impl Serialize) -> io::Result<()> {
    let file = File::create(path)?;
    let mut writer = BufWriter::new(file);
    serde_json::to_writer_pretty(&mut writer, value).map_err(invalid_json)?;
    writer.write_all(b"\n")?;
    writer.flush()?;
    writer.get_ref().sync_all()
}

fn invalid_json(error: serde_json::Error) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, error)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{BuildStats, Index};

    fn index_at(path: &Path, sort: &str) {
        let mut index = Index::default();
        let mut stats = BuildStats::default();
        index
            .ingest_algebra_line(
                &format!(
                    "(: ev (≞ (has_sort ev computer taxonomic_kind {sort}) (stv 1.000 0.900)))"
                ),
                &mut stats,
            )
            .unwrap();
        index.save(path, stats).unwrap();
    }

    #[test]
    fn publishes_switches_and_rolls_back_generations() {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let root = std::env::temp_dir().join(format!("pathmap-snapshots-{nonce}"));
        fs::create_dir_all(&root).unwrap();
        let staged_one = root.join("staged-one");
        let staged_two = root.join("staged-two");
        index_at(&staged_one, "artifact");
        index_at(&staged_two, "machine");
        let manager = SnapshotManager::open(root.join("repository")).unwrap();
        manager.publish("generation-1", &staged_one).unwrap();
        assert_eq!(manager.current_generation().unwrap(), "generation-1");
        manager.publish("generation-2", &staged_two).unwrap();
        assert_eq!(manager.current_generation().unwrap(), "generation-2");
        manager.switch("generation-1").unwrap();
        assert_eq!(manager.current_generation().unwrap(), "generation-1");
        assert!(manager.switch("../escape").is_err());

        let manifest = manager
            .root()
            .join("generations/generation-2/snapshot.json");
        fs::write(&manifest, b"{\"format_version\":\"broken\"}").unwrap();
        assert!(manager.switch("generation-2").is_err());
        assert_eq!(manager.current_generation().unwrap(), "generation-1");

        let incomplete = root.join("incomplete");
        fs::create_dir(&incomplete).unwrap();
        assert!(manager.publish("generation-3", &incomplete).is_err());
        assert_eq!(manager.current_generation().unwrap(), "generation-1");
        fs::remove_dir_all(root).unwrap();
    }
}
