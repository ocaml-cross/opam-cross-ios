#!/bin/sh

set -e

PREFIX="$1"

for pkg in bigarray bytes compiler-libs dynlink profiling runtime_events stdlib str threads unix; do
  if [ -f "${PREFIX}/lib/ocaml/${pkg}/META" ]; then
    mkdir -p "${PREFIX}/ios-sysroot/lib/${pkg}"
    cp "${PREFIX}/lib/ocaml/${pkg}/META" "${PREFIX}/ios-sysroot/lib/${pkg}/META"
  fi
done
