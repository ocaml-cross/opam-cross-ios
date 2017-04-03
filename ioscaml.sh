#!/bin/sh -e

IOSCAMLVER=4.04.0

ioscaml_create_switches() {
  opam switch -y ${IOSCAMLVER}+ios+arm32 --alias-of ${IOSCAMLVER}+32bit
  opam switch -y ${IOSCAMLVER}+ios+arm64 --alias-of ${IOSCAMLVER}
  opam switch -y ${IOSCAMLVER}+ios+x86   --alias-of ${IOSCAMLVER}+32bit
  opam switch -y ${IOSCAMLVER}+ios+amd64 --alias-of ${IOSCAMLVER}
}

ioscaml_foreach() {
  for i in ${IOSCAMLVER}+ios+arm32 ${IOSCAMLVER}+ios+arm64 \
           ${IOSCAMLVER}+ios+x86   ${IOSCAMLVER}+ios+amd64; do
    opam switch -y --no-warning $i
    eval $(opam config env --switch=$i)
    if ! OPAMYES=1 $*; then return 1; fi
  done
}

ioscaml_configure() {
  if [ -z "${SDK}" -o -z "${VER}" ]; then
    echo "Usage: SDK=9.3 VER=8.0 ioscaml_configure" >&2
    echo "  SDK specifies the installed iOS SDK version." >&2
    echo "  VER specifies the -miphoneos-version-min value." >&2
    return 1
  fi
  case $(opam switch show) in
  ${IOSCAMLVER}+ios+arm32)
    ARCH=arm SUBARCH=armv7 PLATFORM=iPhoneOS \
      opam reinstall -y conf-ios
    ;;
  ${IOSCAMLVER}+ios+arm64)
    ARCH=arm64 SUBARCH=arm64 PLATFORM=iPhoneOS \
      opam reinstall -y conf-ios
    ;;
  ${IOSCAMLVER}+ios+x86)
    ARCH=i386 SUBARCH=i386 PLATFORM=iPhoneSimulator \
      opam reinstall -y conf-ios
    ;;
  ${IOSCAMLVER}+ios+amd64)
    ARCH=amd64 SUBARCH=x86_64 PLATFORM=iPhoneSimulator \
      opam reinstall -y conf-ios
    ;;
  esac
}

ioscaml_ocamlbuild() {
  ocamlbuild -build-dir $(opam config var conf-ios:arch) $*
}
