#!/bin/sh
set -e

PREFIX="$1"

for bin in ocaml ocamlc ocamlcmt ocamlcp ocamldep ocamllex ocamlmklib \
           ocamlmktop ocamlobjinfo ocamloptp ocamlprof ocamlrun ocamlrund \
           ocamlruni ocamlyacc; do
  rm -f "${PREFIX}/ios-sysroot/bin/${bin}" \
        "${PREFIX}/ios-sysroot/bin/${bin}.byte"
done

rm -rf "${PREFIX}/ios-sysroot/lib/ocaml"
rm -rf "${PREFIX}/ios-sysroot/device"
rm -f "${PREFIX}/lib/findlib.conf.d/ios-arm32.conf"
