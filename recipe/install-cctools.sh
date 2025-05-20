#!/bin/bash

set -ex

pushd cctools_build_final
  make install
popd

pushd "${PREFIX}"
  # This is packaged in ld64
  rm bin/*-ld
popd

prefix="${macos_machine}-"

pushd $PREFIX/bin
  for tool in $(ls ${prefix}*); do
    ln -s $PREFIX/bin/$tool $PREFIX/bin/${tool:${#prefix}} || true
  done
popd