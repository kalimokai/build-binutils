#!/bin/bash
# Description: A simple build script for binutilities.
# Author: kalimokai
# Version: 1.0.0


BINUTILS_VERSION=""
BUILD_TARGET=""
INSTALL_PATH=""
SCRIPT_NAME=$(basename "$0")

usage() {
    cat << EOF
usage: $SCRIPT_NAME [options]

Required options:
    -v. -- version VERSION Set installation version
    -t. -- build_target TARGET setting to build the target architecture
Optional options:
    -h. -- help Display this help information
Example:
    $SCRIPT_NAME -i /usr/local -v 2.38 -t aarch64-linux-gnu
    $SCRIPT_NAME --install_path /usr/local --version 2.38 --build_target aarch64-linux-gnu
EOF
}

TEMP=$(getopt -o i:v:t:h --long install_path:,version:,build_target:,help -n '$SCRIPT_NAME' -- "$@")

if [ $? != 0 ]; then
    echo "Error: Parameter parsing failed !"
    usage
    exit 1
fi

eval set -- "$TEMP"

while true; do
    case "$1" in
        -i|--install_path)
            INSTALL_PATH="$2"
            shift 2
            ;;
        -v|--version)
            BINUTILS_VERSION="$2"
            shift 2
            ;;
        -t|--build_target)
            BUILD_TARGET="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Internal error !"
            exit 1
            ;;
    esac
done

if [[ -z "$INSTALL_PATH" || -z "$BINUTILS_VERSION" || -z "$BUILD_TARGET" ]]; then
    echo "Error: Missing required parameters !"
    usage
    exit 1
fi

function download_binutils() {
    
    local flag=0
    mkdir -p source
    
    echo "Download binutils source code: binutils-$BINUTILS_VERSION.tar.xz"
    if ! wget -q --show-progress -O "./source/binutils-$BINUTILS_VERSION.tar.xz" "https://sourceware.org/pub/binutils/releases/binutils-$BINUTILS_VERSION.tar.xz"; then
        echo "Error: Download failed !"
        flag=1
    fi

    return $flag
}

function build_binutils() {
    
    local flag=0

    echo "  Install_Path: $INSTALL_PATH"
    echo "  Version: binutils-$BINUTILS_VERSION"
    echo "  BuildTarget: $BUILD_TARGET"

    echo "Decompressing source code"
    if ! tar -xvf ./source/binutils-$BINUTILS_VERSION.tar.xz 2>&1 > tar-binutils-$BINUTILS_VERSION.log; then
        echo "Error: Decompressing failed !"
        flag=1
    fi
    mkdir -p binutils-$BINUTILS_VERSION/build && cd binutils-$BINUTILS_VERSION/build
    
    echo "Compile environment detection"
    if ! ../configure --prefix=$INSTALL_PATH --disable-gdb --disable-gdbserver --disable-weeror --disable-nls --target=$BUILD_TARGET 2>&1 > configure.log; then
        echo "Environmental anomaly !"
        flag=1
    fi
    echo "Compiling"
    if ! (make -j$(nproc --all) 2>&1 > build.log && make install 2>&1 > install.log); then
        echo "Error: Compile failed !"
        flag=1
    fi

    return $flag
}

download_binutils
build_binutils