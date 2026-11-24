//! Versioned metadata for immutable perspective shards.

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::fs::File;
use std::io::{self, BufReader, Read};
use std::path::Path;

pub const SHARD_FORMAT_VERSION: &str = "pathmap-shard/1";
pub const INDEX_METADATA_FILE: &str = "index-metadata.json";
pub const SHARD_METADATA_FILE: &str = "shard-metadata.json";

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct IndexMetadata {
    pub format_version: String,
    pub contract_version: String,
    pub shard_format_version: String,
    pub record_value_size: usize,
    pub shard_count: usize,
    pub symbols: FileMetadata,
    pub payloads: FileMetadata,
    pub shards: Vec<ShardDescriptor>,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct FileMetadata {
    pub file: String,
    pub bytes: u64,
    pub sha256: String,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct ShardDescriptor {
    pub perspective_id: String,
    pub perspective: String,
    pub directory: String,
    pub metadata_file: String,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct ShardMetadata {
    pub format_version: String,
    pub perspective_id: String,
    pub perspective: String,
    pub maps: Vec<MapMetadata>,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct MapMetadata {
    pub name: String,
    pub paths_file: String,
    pub values_file: String,
    pub act_file: String,
    pub act_values_file: String,
    pub path_count: usize,
    pub act_value_count: usize,
    pub paths_bytes: u64,
    pub values_bytes: u64,
    pub act_bytes: u64,
    pub act_values_bytes: u64,
    pub paths_sha256: String,
    pub values_sha256: String,
    pub act_sha256: String,
    pub act_values_sha256: String,
}

pub fn map_metadata(
    directory: &Path,
    name: &str,
    path_count: usize,
    value_size: usize,
) -> io::Result<MapMetadata> {
    let paths_file = format!("{name}.paths");
    let values_file = format!("{name}.values");
    let act_file = format!("{name}.act");
    let act_values_file = format!("{name}.act-values");
    let paths = directory.join(&paths_file);
    let values = directory.join(&values_file);
    let act = directory.join(&act_file);
    let act_values = directory.join(&act_values_file);
    let act_values_bytes = act_values.metadata()?.len();
    let value_size =
        u64::try_from(value_size).map_err(|_| invalid("record value size does not fit in u64"))?;
    if act_values_bytes % value_size != 0 {
        return Err(invalid(format!(
            "ACT values file for {name} is not record-aligned"
        )));
    }
    Ok(MapMetadata {
        name: name.to_owned(),
        paths_file,
        values_file,
        act_file,
        act_values_file,
        path_count,
        act_value_count: usize::try_from(act_values_bytes / value_size)
            .map_err(|_| invalid("ACT value count does not fit in usize"))?,
        paths_bytes: paths.metadata()?.len(),
        values_bytes: values.metadata()?.len(),
        act_bytes: act.metadata()?.len(),
        act_values_bytes,
        paths_sha256: sha256_file(&paths)?,
        values_sha256: sha256_file(&values)?,
        act_sha256: sha256_file(&act)?,
        act_values_sha256: sha256_file(&act_values)?,
    })
}

pub fn file_metadata(directory: &Path, file: &str) -> io::Result<FileMetadata> {
    let path = checked_file(directory, file)?;
    Ok(FileMetadata {
        file: file.to_owned(),
        bytes: path.metadata()?.len(),
        sha256: sha256_file(&path)?,
    })
}

pub fn validate_file(directory: &Path, metadata: &FileMetadata) -> io::Result<()> {
    let path = checked_file(directory, &metadata.file)?;
    let actual_bytes = path.metadata()?.len();
    if actual_bytes != metadata.bytes {
        return Err(invalid(format!(
            "size mismatch for {}: expected {}, received {actual_bytes}",
            path.display(),
            metadata.bytes
        )));
    }
    let actual_digest = sha256_file(&path)?;
    if actual_digest != metadata.sha256 {
        return Err(invalid(format!("SHA-256 mismatch for {}", path.display())));
    }
    Ok(())
}

pub fn validate_map(directory: &Path, metadata: &MapMetadata, value_size: usize) -> io::Result<()> {
    for file in [
        FileMetadata {
            file: metadata.paths_file.clone(),
            bytes: metadata.paths_bytes,
            sha256: metadata.paths_sha256.clone(),
        },
        FileMetadata {
            file: metadata.values_file.clone(),
            bytes: metadata.values_bytes,
            sha256: metadata.values_sha256.clone(),
        },
        FileMetadata {
            file: metadata.act_file.clone(),
            bytes: metadata.act_bytes,
            sha256: metadata.act_sha256.clone(),
        },
        FileMetadata {
            file: metadata.act_values_file.clone(),
            bytes: metadata.act_values_bytes,
            sha256: metadata.act_values_sha256.clone(),
        },
    ] {
        validate_file(directory, &file)?;
    }
    let expected_values = metadata
        .path_count
        .checked_mul(value_size)
        .and_then(|bytes| u64::try_from(bytes).ok())
        .ok_or_else(|| invalid("shard value-size overflow"))?;
    let expected_act_values = metadata
        .act_value_count
        .checked_mul(value_size)
        .and_then(|bytes| u64::try_from(bytes).ok())
        .ok_or_else(|| invalid("ACT shard value-size overflow"))?;
    if metadata.values_bytes != expected_values
        || metadata.act_values_bytes != expected_act_values
        || metadata.act_value_count < metadata.path_count
    {
        return Err(invalid(format!(
            "value count mismatch for {}",
            metadata.name
        )));
    }
    Ok(())
}

pub fn write_json(path: &Path, value: &impl Serialize) -> io::Result<()> {
    let file = File::create(path)?;
    serde_json::to_writer_pretty(file, value).map_err(invalid_json)
}

pub fn read_json<T: for<'de> Deserialize<'de>>(path: &Path) -> io::Result<T> {
    serde_json::from_reader(BufReader::new(File::open(path)?)).map_err(invalid_json)
}

pub fn sha256_file(path: &Path) -> io::Result<String> {
    let mut reader = BufReader::new(File::open(path)?);
    let mut digest = Sha256::new();
    let mut buffer = [0u8; 64 * 1024];
    loop {
        let count = reader.read(&mut buffer)?;
        if count == 0 {
            break;
        }
        digest.update(&buffer[..count]);
    }
    Ok(format!("{:x}", digest.finalize()))
}

fn invalid_json(error: serde_json::Error) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, error)
}

fn checked_file(directory: &Path, file: &str) -> io::Result<std::path::PathBuf> {
    let path = Path::new(file);
    if path.components().count() != 1
        || !matches!(
            path.components().next(),
            Some(std::path::Component::Normal(_))
        )
    {
        return Err(invalid(format!("unsafe shard filename: {file:?}")));
    }
    Ok(directory.join(path))
}

fn invalid(message: impl Into<String>) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, message.into())
}
