#!/bin/bash
set -ex

cd ${SRC_DIR}/cctools_build_final/ld64
make install

#TODO: do we need this?
if [[ ${DEBUG_C} == yes ]]; then
  dsymutil ${PREFIX}/bin/*ld
fi

