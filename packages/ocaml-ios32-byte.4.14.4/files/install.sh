#!/bin/sh
# Install the 32-bit ARM bytecode cross toolchain.  install.sh <prefix>

# Not left to the shebang: opam runs this as `/bin/sh ./install.sh`, which
# ignores the interpreter line, so -e there would have no effect and a
# failing step would be reported as a successful install.
set -e

PREFIX="$1"
SYSROOT="$PREFIX/ios-sysroot"
DEVICE_BINDIR=/usr/local/bin

HOST_OCAMLYACC="$(command -v ocamlyacc)"

# PROGRAMS=ocamlrun because build.sh builds only that runtime; the default
# list also names ocamlrund and ocamlruni, and install fails on the missing
# files. Empty would not do either -- see the note in build.sh.
make install \
  PROGRAMS=ocamlrun \
  OCAMLYACC="$HOST_OCAMLYACC" \
  TARGET_BINDIR="$DEVICE_BINDIR"

# runtime/ocamlrun still holds the host copy from build.sh, so the installed
# bin/ocamlrun is the one that runs the cross compiler. ocamlyacc, being a C
# program, was built for the target and must be replaced with a host binary.
cp "$HOST_OCAMLYACC" "$SYSROOT/bin/ocamlyacc"

# The target runtime, for copying to the device. Signing it is optional on a
# jailbroken device but harmless, and ldid is not assumed to be installed.
mkdir -p "$SYSROOT/device"
cp device/ocamlrun "$SYSROOT/device/ocamlrun"
chmod 755 "$SYSROOT/device/ocamlrun"
if command -v ldid >/dev/null 2>&1; then
  ldid -S "$SYSROOT/device/ocamlrun"
fi

mkdir -p "$PREFIX/lib/findlib.conf.d"
cp ios-arm32.conf "$PREFIX/lib/findlib.conf.d/"

cat <<EOF

ocaml-ios32-byte installed in $SYSROOT

  $SYSROOT/bin/ocamlc          cross compiler (runs here)
  $SYSROOT/device/ocamlrun     target runtime (copy to the device)

Copy the runtime to $DEVICE_BINDIR/ocamlrun on the device; programs linked
by this compiler look for it there. Linking any library with C stubs
selects -custom automatically, since this build has no shared libraries,
and those executables are self-contained and need no runtime installed.

Do not sign a -custom executable: ldid rebuilds the Mach-O from its load
commands and discards the bytecode appended past the last segment, leaving
a runtime that reports "no bytecode file specified". Sign ocamlrun instead,
and only if the device requires it.

With findlib:  ocamlfind -toolchain ios-arm32 ocamlc ...
EOF
