#!/bin/bash

set -ex

pushd cctools_build_final/ld64
  make install
  if [[ ${DEBUG_C} == yes ]]; then
    dsymutil ${PREFIX}/bin/*ld
  fi
popd

# Add an absolute LC_RPATH so libtapi.dylib is found regardless of how the
# binary is invoked. The default @loader_path/../lib/ rpath fails when
# conda-build extracts the package to a temp pkgs cache on a different
# filesystem and uses softlinks: macOS dyld resolves @loader_path to the
# softlink target (the cache directory), where lib/ does not exist.
# conda-build's prefix replacement rewrites this absolute path to the
# user's install prefix at install time.
install_name_tool -add_rpath "${PREFIX}/lib" "${PREFIX}/bin/${macos_machine}-ld"
# install_name_tool invalidates the code signature; re-sign ad-hoc.
codesign --remove-signature "${PREFIX}/bin/${macos_machine}-ld" 2>/dev/null || true
codesign --sign - "${PREFIX}/bin/${macos_machine}-ld"

ln -s $PREFIX/bin/${macos_machine}-ld $PREFIX/bin/ld