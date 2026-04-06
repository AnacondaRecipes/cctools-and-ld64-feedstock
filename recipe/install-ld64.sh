#!/bin/bash

set -ex

pushd cctools_build_final/ld64
  make install
  if [[ ${DEBUG_C} == yes ]]; then
    dsymutil ${PREFIX}/bin/*ld
  fi
popd

# Ensure the ld binary has an absolute LC_RPATH to find libtapi.dylib
# regardless of how the binary is invoked. The default @loader_path/../lib/
# rpath fails when conda-build extracts the package to a temp pkgs cache
# on a different filesystem and uses softlinks: macOS dyld resolves
# @loader_path to the softlink target (the cache directory), where lib/
# does not exist.
#
# conda's LDFLAGS normally includes -Wl,-rpath,$PREFIX/lib which adds this
# rpath at link time. If for some reason it's missing, add it via
# install_name_tool (and re-sign the binary). conda-build's prefix
# replacement rewrites the absolute path to the user's install prefix at
# install time.
if ! otool -l "${PREFIX}/bin/${macos_machine}-ld" | grep -q " path ${PREFIX}/lib "; then
  install_name_tool -add_rpath "${PREFIX}/lib" "${PREFIX}/bin/${macos_machine}-ld"
  codesign --remove-signature "${PREFIX}/bin/${macos_machine}-ld" 2>/dev/null || true
  codesign --sign - "${PREFIX}/bin/${macos_machine}-ld"
fi

ln -s $PREFIX/bin/${macos_machine}-ld $PREFIX/bin/ld