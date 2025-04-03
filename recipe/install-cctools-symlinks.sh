#!/bin/bash
set -exo pipefail

prefix="${macos_machine}-"

pushd $PREFIX/bin
  for tool in $(ls ${prefix}*); do
    echo "Symlinking $PREFIX/bin/$tool to $PREFIX/bin/${tool:${#prefix}}"
    ln -sv $PREFIX/bin/$tool $PREFIX/bin/${tool:${#prefix}} || true
  done
popd
