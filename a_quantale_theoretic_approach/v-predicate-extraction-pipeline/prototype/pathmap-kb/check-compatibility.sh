#!/usr/bin/env bash
set -euo pipefail

crate_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ffi_dir="$crate_dir/../pathmap-kb-ffi"
expected_revision="72ebdba08095d01ac31bb609190589436efd6854"
expected_version="0.4.0"

python3 - "$crate_dir" "$expected_revision" "$expected_version" <<'PY'
import json
import pathlib
import subprocess
import sys

crate = pathlib.Path(sys.argv[1])
revision = sys.argv[2]
version = sys.argv[3]
metadata = json.loads(
    subprocess.check_output(
        ["cargo", "metadata", "--locked", "--format-version", "1"],
        cwd=crate,
        text=True,
    )
)
packages = [package for package in metadata["packages"] if package["name"] == "pathmap"]
if len(packages) != 1:
    raise SystemExit(f"expected exactly one PathMap package, found {len(packages)}")
package = packages[0]
source = package.get("source") or ""
if package["version"] != version:
    raise SystemExit(
        f"PathMap version mismatch: expected {version}, received {package['version']}"
    )
if revision not in source:
    raise SystemExit(
        f"PathMap revision mismatch: expected {revision}, source was {source!r}"
    )
print(f"verified PathMap {version} at {revision}")
PY

cargo test --manifest-path "$crate_dir/Cargo.toml" --locked --all-targets
cargo check --manifest-path "$ffi_dir/Cargo.toml" --locked
