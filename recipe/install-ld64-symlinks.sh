#!/bin/bash
set -exo pipefail

ls -la $PREFIX/bin
ln -sv $PREFIX/bin/${macos_machine}-ld $PREFIX/bin/ld
