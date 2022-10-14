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
  if [ -d "${PREFIX}/lib/${pkg}" ]; then
    cp -r "${PREFIX}/lib/${pkg}" "${PREFIX}/ios-sysroot/lib/"
  fi
done

mkdir -p "${PREFIX}/lib/findlib.conf.d"
cp ios.conf "${PREFIX}/lib/findlib.conf.d"
