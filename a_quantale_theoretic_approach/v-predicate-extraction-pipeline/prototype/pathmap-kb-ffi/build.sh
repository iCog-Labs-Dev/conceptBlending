#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RUSTFLAGS="-C target-cpu=native" cargo build --release
eval "$(swipl --dump-runtime-variables)"
gcc -O3 -shared -fPIC -pthread -o pathmaplib.so pathmap_kb.c \
  -I"$PLBASE/include" -L"$PLLIBDIR" -lswipl \
  -L"$SCRIPT_DIR/target/release" -lpathmap_kb_ffi \
  -Wl,-rpath,"$PLLIBDIR" -Wl,-rpath,'$ORIGIN/target/release'

echo "Successfully built pathmap_kb_ffi"
