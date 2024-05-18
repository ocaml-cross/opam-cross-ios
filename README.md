opam-cross-ios
==============

This OPAM repository contains an iOS toolchain featuring OCaml 4.14.2 and 5.0.0 and some commonly used packages.

The supported build system is macOS 10.9 and later. The supported target systems are iOS devices, 64-bit x86 and ARM iOS simulators, and Mac Catalyst.

Installation
------------

For 64-bit iOS device and simulator cross-compiling, switch to a regular OCaml compiler. Its version must match the version of the cross-compiler:

    opam switch 4.14.2
    eval $(opam env)

Add this repository to OPAM:

    opam repository add ios https://github.com/ocaml-cross/opam-cross-ios.git

Configure the compiler for 64-bit ARM device:

    ARCH=arm64 SUBARCH=arm64 PLATFORM=iPhoneOS SDK=$(xcrun --sdk iphoneos --show-sdk-version) VER=12.0 \
      opam install conf-ios

or for the ARM iOS simulator:

    opam install conf-simulator-ios
    ARCH=arm64 SUBARCH=arm64 PLATFORM=iPhoneSimulator SDK=$(xcrun --sdk iphonesimulator --show-sdk-version) VER=12.0 \
      opam install conf-ios

or for the x86 iOS simulator:

    opam install conf-simulator-ios
    ARCH=amd64 SUBARCH=x86_64 PLATFORM=iPhoneSimulator SDK=$(xcrun --sdk iphonesimulator --show-sdk-version) VER=12.0 \
      opam install conf-ios

or for Mac Catalyst:

    opam install conf-maccatalyst
    ARCH=amd64 SUBARCH=x86_64 PLATFORM=MacOSX SDK=$(xcrun --show-sdk-version) VER=15.0 opam install conf-ios

32-bit iOS device cross-compiling is only supported in OCaml 4.04.0. Switch to a 32-bit compiler when compiling for 32-bit targets:

    opam switch 4.04.0+32bit
    eval `opam config env`

Configure the compiler for 32-bit ARM:

    ARCH=arm SUBARCH=armv7s PLATFORM=iPhoneOS SDK=$(xcrun --sdk iphoneos --show-sdk-version) VER=9.0 \
      opam install conf-ios

... for 32-bit x86:

    ARCH=i386 SUBARCH=i386 PLATFORM=iPhoneSimulator SDK=16.0 VER=12.0 \
      opam install conf-ios

Some options can be further tweaked:

  * `SUBARCH` (when `ARCH=arm`) specifies the ARM architecture version, one of `armv6`, `armv7`, and `armv7s`;
  * `SDK` specifies the SDK being used as well as the minimum iOS version on which the compiled code will run;
  * `VER` specifies the value of the `-miphoneos-version-min` compiler switch.

The options above (`ARCH`, `SUBARCH`, `PLATFORM`, `SDK`) are recorded inside the `conf-ios` package, so make sure to reinstall that package if you wish to switch to a different toolchain. Otherwise, it is not necessary to supply them while upgrading the `ocaml-ios*` packages.

If desired, request the compiler to be built with [flambda][] optimizers:

    opam install conf-flambda-ios

[flambda]: https://caml.inria.fr/pub/docs/manual-ocaml/flambda.html

Install the compiler and some packages:

    opam install ocaml-ios re-ios

Write some code using them:

    let () =
      let regexp = Re.Pcre.regexp {|\b([a-z]+)\b|} in
      let result = Re.exec regexp "Hello, world!" in
      Format.printf "match: %s\n" (Re.Group.get result 1)

Make an object file out of it, link `libasmrun.a` to your final executable, and link it with your iOS project (you'll need to call `caml_startup(argv)` to run OCaml code; see [this article](http://www.mega-nerd.com/erikd/Blog/CodeHacking/Ocaml/calling_ocaml.html)):

    ocamlfind -toolchain ios ocamlopt -package re.pcre -linkpkg -output-complete-obj test_pcre.ml -o test_pcre.o

With opam-ios, cross-compilation is easy!

Managing deployment targets
---------------------------

Generally, any native iOS library would have to be compiled four times: for 32-bit and 64-bit device and simulator. OPAM offers no help here; due to the way OPAM packages currently work, the only realistic option is to create four switches, one switch per target, and build everything four times. To assist with this, a script called [ioscaml.sh](/ioscaml.sh) is distributed in this repository.

The script is supposed to be loaded into a running shell by sourcing it and it defines several functions:

  * `ioscaml_create_switches` creates four OPAM switches with predefined names;
  * `ioscaml_foreach cmd...` runs `cmd...` in every OPAM switch;
  * `SDK=9.3 VER=8.0 ioscaml_configure` installs `conf-ios` with appropriate parameters and specified SDK version as well as `-miphoneos-version-min` in every switch;
  * `ioscaml_ocamlbuild` runs `ocamlbuild` once with every OPAM switch selected and places the build products in `_build_arm` for 32-bit iOS, `_build_arm64` for 64-bit iOS, `_build_i386` for 32-bit simulator, and `_build_amd64` for 64-bit simulator.

A typical workflow would be as follows:

  * `ioscaml_create_switches` to create the switches and build the host compilers;
  * `SDK=9.3 VER=8.0 ioscaml_foreach ioscaml_configure` to configure the cross-compiler in the switches;
  * `ioscaml_foreach opam pin ...` to pin the necessary dependencies;
  * `ioscaml_foreach opam install re-ios ...` to install the dependencies of your library;
  * `ioscaml_foreach ioscaml_ocamlbuild libiosthing.o` to build your library.

Porting packages
----------------

OCaml packages often have components that execute at compile-time (camlp4 or ppx syntax extensions, cstubs, OASIS, ...). Thus, it is not possible to just blanketly cross-compile every package in the OPAM repository; sometimes you would even need a cross-compiled and a non-cross-compiled package at once. The package definitions also often need package-specific modification in order to work.

As a result, if you want a package to be cross-compiled, you have to copy the definition from [opam-repository](https://github.com/ocaml/opam-repository), rename the package to add `-ios` suffix while updating any dependencies it could have, and update the build script. Don't forget to add `ocaml-ios` as a dependency!

Findlib 1.5.4 adds a feature that makes porting packages much simpler; namely, an `OCAMLFIND_TOOLCHAIN` environment variable that is equivalent to the `-toolchain` command-line flag. Now it is not necessary to patch the build systems of the packages to select the iOS toolchain; it is often enough to add `["env" "OCAMLFIND_TOOLCHAIN=ios" make ...]` to the build command in the `opam` file.

Note that iOS does not support dynamic linking, and so package build systems should be instructed to not build plugins (`*.cmxs`).

For projects using OASIS, the following steps will work:

    build: [
      ["env" "OCAMLFIND_TOOLCHAIN=ios"
       "ocaml" "setup.ml" "-configure" "--prefix" "%{prefix}%/ios-sysroot"
                                       "--override" "native_dynlink" "false"]
      ["env" "OCAMLFIND_TOOLCHAIN=ios" "ocaml" "setup.ml" "-build"]
    ]
    install: [
      ["env" "OCAMLFIND_TOOLCHAIN=ios" "ocaml" "setup.ml" "-install"]
    ]
    remove: [["ocamlfind" "-toolchain" "ios" "remove" "pkg"]]
    depends: ["ocaml-ios" ...]

For projects installing the files via OPAM's `.install` files (e.g. [topkg](https://github.com/dbuenzli/topkg)), the following steps will work:

    build: [["ocaml" "pkg/pkg.ml" "build" "--pinned" "%{pinned}%" "--toolchain" "ios" ]]
    install: [["opam-installer" "--prefix=%{prefix}%/ios-sysroot" "pkg.install"]]
    remove: [["ocamlfind" "-toolchain" "ios" "remove" "pkg"]]
    depends: ["ocaml-ios" ...]

The output of the `configure` script will be entirely wrong, referring to the host configuration rather than target configuration. Thankfully, it is not actually used in the build process itself, so it doesn't matter.

Internals
---------

The aim of this repository is to build a cross-compiler while altering the original codebase in the minimal possible way. There are no attempts to alter the `configure` script; rather, the configuration is provided directly. The resulting cross-compiler has several interesting properties:

  * All paths to the iOS toolchain are embedded inside `ocamlc` and `ocamlopt`; thus, no knowledge of the iOS toolchain is required even for packages that have components in C, provided they use the OCaml driver to compile the C code. (This is usually the case.)
  * The build system makes several assumptions that are not strictly valid while cross-compiling, mainly the fact that the bytecode the cross-compiler has just built can be ran by the `ocamlrun` on the build system. Thus, the requirement for a 32-bit build compiler for 32-bit targets, as well as for the matching versions.
  * The `.opt` versions of the compiler are built using itself, which doesn't work while cross-compiling, so all provided tools are bytecode-based.

Acknowledgements
----------------

The OCaml cross-compiler in opam-cross-ios is based on a [patchset][psellos] by Gerd Stolpmann.

[psellos]: psellos.com/ocaml/compile-to-iphone.html

License
-------

All files contained in this repository are licensed under the [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/) license.

References
----------

See also [opam-cross-windows](https://github.com/whitequark/opam-cross-windows) and [opam-cross-android](https://github.com/whitequark/opam-cross-android).
