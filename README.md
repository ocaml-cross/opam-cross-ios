opam-cross-ios
==============

This repository contains an up-to-date iOS toolchain featuring OCaml 4.02.3, as well as some commonly used packages.

The supported build systems is OS X 10.9 and later. The supported target systems are 32-bit and 64-bit x86 iPhone simulator and ARM iPhone.

If you need support for other platforms or versions, please [open an issue](https://github.com/whitequark/opam-cross-ios/issues).

Installation
------------

Add this repository to OPAM:

    opam repository add ios git://github.com/whitequark/opam-cross-ios

Switch to 32-bit compiler when compiling for 32-bit targets:

    opam switch 4.02.3+32bit
    eval `opam config env`

Otherwise, use a regular compiler; its version must match the version of the cross-compiler:

    opam switch 4.02.3
    eval `opam config env`

Configure the compiler for 32-bit ARM:

    ARCH=arm SUBARCH=armv7s PLATFORM=iPhoneOS SDK=9.3 \
      opam install conf-ios

... for 64-bit ARM

    ARCH=arm64 SUBARCH=arm64 PLATFORM=iPhoneOS SDK=9.3 \
      opam install conf-ios

... for 32-bit x86:

    ARCH=i386 SUBARCH=i386 PLATFORM=iPhoneSimulator SDK=9.3 \
      opam install conf-ios

... for 64-bit x86:

    ARCH=amd64 SUBARCH=x86_64 PLATFORM=iPhoneSimulator SDK=9.3 \
      opam install conf-ios

Some options can be further tweaked:

  * `SUBARCH` (when `ARCH=arm`) specifies the ARM architecture version, one of `armv6`, `armv7`, and `armv7s`;
  * `SDK` specifies the SDK being used as well as the minimum iOS version on which the compiled code will run.

The options above (`ARCH`, `SUBARCH`, `PLATFORM`, `SDK`) are recorded inside the `conf-ios` package, so make sure to reinstall that package if you wish to switch to a different toolchain. Otherwise, it is not necessary to supply them while upgrading the `ocaml-ios*` packages.

Install the compiler and some packages:

    opam install ocaml-ios re-ios

Write some code using them:

    let () =
      let regexp = Re_pcre.regexp {|\b([a-z]+)\b|} in
      let result = Re.exec regexp "Hello, world!" in
      Format.printf "match: %s\n" (Re.get result 1)

Make an object file out of it and link it with your iOS project (you'll need to call `caml_startup(argv)` to run OCaml code; see [this article](http://www.mega-nerd.com/erikd/Blog/CodeHacking/Ocaml/calling_ocaml.html)):

    ocamlfind -toolchain ios ocamlopt -package re.pcre -linkpkg -output-complete-obj test_pcre.ml -o test_pcre.o

With opam-ios, cross-compilation is easy!

Porting packages
----------------

OCaml packages often have components that execute at compile-time (camlp4 or ppx syntax extensions, cstubs, OASIS, ...). Thus, it is not possible to just blanketly cross-compile every package in the OPAM repository; sometimes you would even need a cross-compiled and a non-cross-compiled package at once. The package definitions also often need package-specific modification in order to work.

As a result, if you want a package to be cross-compiled, you have to copy the definition from [opam-repository](https://github.com/ocaml/opam-repository), rename the package to add `-ios` suffix while updating any dependencies it could have, and update the build script. Don't forget to add `ocaml-ios` as a dependency!

Findlib 1.5.4 adds a feature that makes porting packages much simpler; namely, an `OCAMLFIND_TOOLCHAIN` environment variable that is equivalent to the `-toolchain` command-line flag. Now it is not necessary to patch the build systems of the packages to select the iOS toolchain; it is often enough to add `["env" "OCAMLFIND_TOOLCHAIN=ios" make ...]` to the build command in the `opam` file.

Note that iOS does not support dynamic linking, and so package build systems should be instructed to not build plugins (`*.cmxs`).

For projects using OASIS, the following steps will work:

    build: [
      ["ocaml" "setup.ml" "-configure" "--prefix" "%{prefix}%/ios-sysroot"
                                       "--override" "native_dynlink" "false"]
      ["env" "OCAMLFIND_TOOLCHAIN=ios" "ocaml" "setup.ml" "-build"]
      ["env" "OCAMLFIND_TOOLCHAIN=ios" "ocaml" "setup.ml" "-install"]
    ]
    remove: [["ocamlfind" "-toolchain" "ios" "remove" "pkg"]]
    depends: ["ocaml-ios" ...]

For projects installing the files via OPAM's `.install` files (e.g. [topkg](https://github.com/dbuenzli/topkg)), the following steps will work:

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
