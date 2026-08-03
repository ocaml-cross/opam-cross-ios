#!/bin/sh
# Configure a C cross toolchain for one 32-bit ARM iOS target.
#
#   SUBARCH=armv6 SYSROOT=/path/to/iPhoneOS4.2.sdk opam install conf-ios-arm32
#
# As with conf-ios, the target is fixed at install time and recorded in the
# package; reinstall it to switch to a different one.
#
#   SUBARCH   armv6 | armv7 | armv7s          (required)
#   SYSROOT   path to the SDK                 (or give SDK and PLATFORM)
#   SDK       SDK version, e.g. 4.2           } resolved under xcode-select
#   PLATFORM  platform name, default iPhoneOS } like conf-ios does
#   VER       deployment target, default: the SDK's own version
#
# Apple has not shipped an SDK with a 32-bit ARM slice for many years and
# one cannot be downloaded automatically. Old SDKs are found inside the
# matching Xcode installer; "Xcode 3.2.5 and iOS SDK 4.2", for instance,
# carries Packages/iPhoneSDK4_2.pkg, which pkgutil --expand-full unpacks.

# Not left to the shebang: opam runs this as `sh ./setup.sh`, which ignores
# the interpreter line, so -e there would have no effect.
set -e

BINDIR="$1"

PLATFORM="${PLATFORM:-iPhoneOS}"
SYSROOT="${SYSROOT:-${IOS_ARM_SDK:-}}"
if [ -z "$SYSROOT" ] && [ -n "$SDK" ]; then
  SYSROOT="$(xcode-select -p)/Platforms/$PLATFORM.platform/Developer/SDKs/$PLATFORM$SDK.sdk"
fi
if [ -z "$SYSROOT" ]; then
  echo "Set SYSROOT to the SDK path (or SDK=<version> to resolve it under" \
       "xcode-select); see the comments in setup.sh." >&2
  exit 1
fi

case "$SUBARCH" in
  armv6)  CPU=arm1176jzf-s ;;
  armv7)  CPU=cortex-a8 ;;
  armv7s) CPU=swift ;;
  "") echo "SUBARCH is not set (armv6, armv7 or armv7s)." >&2; exit 1 ;;
  *)  echo "SUBARCH=$SUBARCH is not a 32-bit ARM iOS architecture." >&2
      exit 1 ;;
esac

# Current SDKs describe libSystem with a .tbd stub and ship no crt1.o, so a
# missing one of these means the SDK is too new rather than malformed.
for f in "$SYSROOT/usr/include/stdio.h" "$SYSROOT/usr/lib/libSystem.dylib" \
         "$SYSROOT/usr/lib/crt1.o"; do
  if [ ! -e "$f" ]; then
    echo "$SYSROOT has no $(basename "$f"); it is not an SDK old enough to" \
         "target 32-bit ARM." >&2
    exit 1
  fi
done

if ! lipo -info "$SYSROOT/usr/lib/libSystem.dylib" 2>/dev/null \
     | grep -qw "$SUBARCH"; then
  echo "libSystem in $SYSROOT has no $SUBARCH slice (it has:" \
       "$(lipo -info "$SYSROOT/usr/lib/libSystem.dylib" | sed 's/.*: //'))." >&2
  exit 1
fi

# ARMv6 and ARMv7 have no integer division instruction and current
# compiler-rt has no slice for them, so the builtins come from the SDK's
# libgcc. Its triple and version vary by SDK release; ARMv7s divides in
# hardware and the SDKs supporting it ship no libgcc.
GCCLIB=
for d in $(ls -d "$SYSROOT"/usr/lib/gcc/arm-apple-darwin*/*/ 2>/dev/null | sort -V); do
  [ -e "${d}libgcc_static.a" ] && GCCLIB="${d%/}"
done
if [ -z "$GCCLIB" ] && [ "$SUBARCH" != armv7s ]; then
  echo "No libgcc_static.a under $SYSROOT/usr/lib/gcc, but $SUBARCH needs it" \
       "for the division builtins." >&2
  exit 1
fi

if [ -z "$VER" ]; then
  VER=$(/usr/libexec/PlistBuddy -c 'Print :Version' \
          "$SYSROOT/SDKSettings.plist" 2>/dev/null || true)
fi
if [ -z "$VER" ]; then
  VER=$(basename "$SYSROOT" | sed "s/^$PLATFORM//; s/\.sdk\$//")
fi

CC="$BINDIR/$SUBARCH-apple-darwin10-clang"

mkdir -p "$BINDIR"
cp fix-version-min "$BINDIR/ios-arm32-fix-version-min"
sed -e "s|@SDK@|$SYSROOT|g" -e "s|@GCCLIB@|$GCCLIB|g" -e "s|@DEPLOY@|$VER|g" \
  ios-arm-clang.in > "$BINDIR/ios-arm-clang"
chmod 755 "$BINDIR/ios-arm-clang" "$BINDIR/ios-arm32-fix-version-min"
# The driver takes its target from the name it is called as.
ln -sf ios-arm-clang "$CC"

CFLAGS="-target $SUBARCH-apple-ios$VER -mcpu=$CPU -isysroot $SYSROOT"
LDFLAGS="-Wl,-syslibroot,$SYSROOT"
[ -z "$GCCLIB" ] || LDFLAGS="$LDFLAGS -L$GCCLIB -lgcc_static"

cat > conf-ios-arm32.config <<EOF
opam-version: "2.0"
variables {
  arch: "arm"
  subarch: "$SUBARCH"
  platform: "$PLATFORM"
  sysroot: "$SYSROOT"
  ver: "$VER"
  cc: "$CC"
  cflags: "$CFLAGS"
  ldflags: "$LDFLAGS"
  triple: "arm-apple-darwin10"
}
EOF

echo "conf-ios-arm32: $SUBARCH ($CPU), iOS $VER, sysroot $SYSROOT"
