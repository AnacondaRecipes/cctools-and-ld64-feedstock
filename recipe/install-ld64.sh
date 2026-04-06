#!/bin/bash

set -ex

pushd cctools_build_final/ld64
  make install
  if [[ ${DEBUG_C} == yes ]]; then
    dsymutil ${PREFIX}/bin/*ld
  fi
popd

# Bundle libtapi.dylib INSIDE the ld64 package at a location adjacent to
# the ld binary, and rewrite LC_LOAD_DYLIB to load it via @loader_path.
#
# Why: conda-build's binary relocation rewrites BOTH absolute LC_RPATH
# AND absolute LC_LOAD_DYLIB paths back to @rpath/@loader_path form for
# portability. So we cannot use absolute paths to libtapi — they get
# rewritten away during packaging.
#
# The fundamental problem is that libtapi is in a SEPARATE conda package
# (tapi). When conda-build extracts ld64 and tapi into separate temp
# cache directories and uses softlinks (cross-filesystem fallback),
# macOS dyld follows the symlink to the ld64 cache dir, where libtapi
# is not adjacent. @loader_path, @executable_path, and @rpath all
# follow the symlink to the cache target.
#
# Fix: copy libtapi.dylib into ld64's own bin/_lib/ directory. Now both
# the binary and libtapi are in the same package (same cache extraction
# directory), so @loader_path/_lib/libtapi.dylib resolves correctly
# even after symlink-following. The path is relative (no prefix),
# so conda-build leaves it alone.
mkdir -p "${PREFIX}/bin/_lib"
cp "${PREFIX}/lib/libtapi.dylib" "${PREFIX}/bin/_lib/libtapi.dylib"
install_name_tool -change @rpath/libtapi.dylib @loader_path/_lib/libtapi.dylib "${PREFIX}/bin/${macos_machine}-ld"
# install_name_tool invalidates the code signature; re-sign ad-hoc.
codesign --remove-signature "${PREFIX}/bin/${macos_machine}-ld" 2>/dev/null || true
codesign --sign - "${PREFIX}/bin/${macos_machine}-ld"

ln -s $PREFIX/bin/${macos_machine}-ld $PREFIX/bin/ld