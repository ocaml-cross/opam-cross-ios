#!/bin/sh
# Build an OCaml bytecode cross-compiler for a 32-bit ARM iOS target.
#
#   build.sh <prefix> <cc>
#
# Two runtimes come out of this, and keeping them straight is the whole
# trick. The cross compiler is itself bytecode and runs on the build
# machine, so it needs a host ocamlrun; the programs it produces run on the
# phone, so they need a target one. Anything the *build* executes -- the
# bootstrap compiler, ocamlyacc -- must likewise be a host binary, even
# though this tree is configured to emit 32-bit ARM.

# Not left to the shebang: opam runs this as `/bin/sh ./build.sh`, which
# ignores the interpreter line, so -e there would have no effect.
set -e

PREFIX="$1"
CC="$2"
SYSROOT="$PREFIX/ios-sysroot"

# Where ocamlrun will live on the device; baked into the #! line of every
# bytecode executable the cross compiler links.
DEVICE_BINDIR=/usr/local/bin

HOST_OCAMLRUN="$(command -v ocamlrun)"
HOST_OCAMLYACC="$(command -v ocamlyacc)"
[ -n "$HOST_OCAMLRUN" ] || { echo "no ocamlrun in PATH" >&2; exit 1; }
[ -n "$HOST_OCAMLYACC" ] || { echo "no ocamlyacc in PATH" >&2; exit 1; }

./configure \
  --host=arm-apple-darwin10 \
  --prefix="$SYSROOT" \
  --disable-native-compiler \
  --disable-ocamldoc \
  --disable-ocamltest \
  --disable-shared \
  --disable-debugger \
  CC="$CC"

# sak generates headers during the build, so it stays a host binary.
make -C runtime sak SAK_CC=cc SAK_LINK='cc -o $(1) $(2)'

# The target runtime, set aside before the host one takes its place.
make -C runtime ocamlrun libcamlrun.a SAK_CC=cc SAK_LINK='cc -o $(1) $(2)'
mkdir -p device
cp runtime/ocamlrun device/ocamlrun
cp "$HOST_OCAMLRUN" runtime/ocamlrun

# PROGRAMS= keeps coldstart from rebuilding runtime/ocamlrun for the target,
# over the host copy the build depends on. It must be dropped again for
# `make install`, where an empty PROGRAMS reduces to `install -c -p <dir>`
# and fails.
make world \
  PROGRAMS= \
  OCAMLYACC="$HOST_OCAMLYACC" \
  TARGET_BINDIR="$DEVICE_BINDIR" \
  SAK_CC=cc SAK_LINK='cc -o $(1) $(2)'
