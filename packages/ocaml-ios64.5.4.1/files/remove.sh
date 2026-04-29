#!/bin/sh -e

PREFIX="$1"

for bin in ocaml ocamlc ocamlcp ocamldebug ocamldep ocamldoc ocamllex ocamlmklib ocamlmktop ocamlobjinfo ocamlopt ocamloptp ocamlprof ocamlrun ocamlyacc; do
  rm -f "${PREFIX}/ios-sysroot/bin/${bin}"
done

rm -rf "${PREFIX}/ios-sysroot/lib/ocaml"
rm -f "${PREFIX}/lib/findlib.conf.d/ios.conf"
