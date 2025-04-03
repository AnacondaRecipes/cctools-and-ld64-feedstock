#!/bin/bash
set -exo pipefail

cd ${SRC_DIR}/cctools_build_final/ld64
make install

if [[ ${DEBUG_C} == yes ]]; then
  dsymutil ${PREFIX}/bin/*ld
fi

