#!/bin/bash

set -ex

pushd cctools_build_final/ld64
  make install
  if [[ ${DEBUG_C} == yes ]]; then
    dsymutil ${PREFIX}/bin/*ld
  fi
popd

# Rewrite LC_LOAD_DYLIB for libtapi from @rpath/libtapi.dylib to an
# absolute ${PREFIX}/lib/libtapi.dylib path.
#
# Why: the default @rpath/libtapi.dylib fails when conda-build extracts
# the package into a temp pkgs cache on a different filesystem and uses
# softlinks: macOS dyld follows the symlink when resolving @rpath via
# @loader_path/../lib (the only LC_RPATH entry), landing in the cache
# directory where lib/ does not exist. @executable_path has the same
# issue (verified — it also follows symlinks).
#
# LC_LOAD_DYLIB with an absolute path does NOT go through rpath
# resolution, so it's not affected by the symlink-follow behavior.
# conda-build detects the prefix string in the binary and rewrites it
# to the user's install prefix at install time via its binary prefix
# replacement mechanism.
install_name_tool -change @rpath/libtapi.dylib "${PREFIX}/lib/libtapi.dylib" "${PREFIX}/bin/${macos_machine}-ld"
# install_name_tool invalidates the code signature; re-sign ad-hoc.
codesign --remove-signature "${PREFIX}/bin/${macos_machine}-ld" 2>/dev/null || true
codesign --sign - "${PREFIX}/bin/${macos_machine}-ld"

ln -s $PREFIX/bin/${macos_machine}-ld $PREFIX/bin/ld