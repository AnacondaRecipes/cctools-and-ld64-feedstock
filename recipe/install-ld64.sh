#!/bin/bash

set -ex

cd "${SRC_DIR}"

pushd cctools_build_final/ld64
  make install
  if [[ ${DEBUG_C} == yes ]]; then
    dsymutil ${PREFIX}/bin/*ld
  fi
popd

ln -s $PREFIX/bin/${macos_machine}-ld $PREFIX/bin/ld