#!/bin/sh -e

PREFIX="$1"

for pkg in bigarray bytes compiler-libs dynlink findlib graphics num num-top stdlib str threads unix; do
  cp -r "${PREFIX}/lib/${pkg}" "${PREFIX}/ios-sysroot/lib/"
done

mkdir -p "${PREFIX}/lib/findlib.conf.d"
cp ios.conf "${PREFIX}/lib/findlib.conf.d"

(cd "${PREFIX}/ios-sysroot/bin/" && ln -sf ocamlc.byte ocamlc)
