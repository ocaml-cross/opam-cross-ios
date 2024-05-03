#!/bin/sh -e

PREFIX="$1"

make install PROGRAMS=ocamlrun

cp compilerlibs/ocamlcommon.cmxa compilerlibs/ocamlcommon.a \
   compilerlibs/ocamlbytecomp.cmxa compilerlibs/ocamlbytecomp.a \
   compilerlibs/ocamloptcomp.cmxa compilerlibs/ocamloptcomp.a \
   driver/main.cmx driver/main.o \
   driver/optmain.cmx driver/optmain.o \
   "${PREFIX}/ios-sysroot/lib/ocaml/compiler-libs"

for pkg in bigarray bytes compiler-libs dynlink findlib graphics stdlib str threads unix; do
  if [ -f "${PREFIX}/lib/ocaml/${pkg}/META" ]; then
    mkdir -p "${PREFIX}/ios-sysroot/lib/${pkg}"
    cp "${PREFIX}/lib/ocaml/${pkg}/META" "${PREFIX}/ios-sysroot/lib/${pkg}/META"
  fi
done

mkdir -p "${PREFIX}/lib/findlib.conf.d"
cp ios.conf "${PREFIX}/lib/findlib.conf.d"
