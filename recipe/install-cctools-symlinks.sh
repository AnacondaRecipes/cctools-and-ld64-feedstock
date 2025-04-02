set -x

prefix="${macos_machine}-"

pushd $PREFIX/bin
  for tool in $(ls ${prefix}*); do
    echo "creating symlink for  $PREFIX/bin/$tool"
    ln -svf $PREFIX/bin/$tool $PREFIX/bin/${tool:${#prefix}}
  done
popd
