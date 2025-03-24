#!/bin/bash
set -ex
cd ${SRC_DIR}/cctools_build_final
make install VERBOSE=1

cd ${PREFIX}
# This is packaged in ld64
rm -rf bin/*-ld

