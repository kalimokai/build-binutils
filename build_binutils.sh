#!/bin/bash
# Description: A simple build script for binutilities.
# Author: kalimokai
# Version: 1.0.0


BINUTILS_VERSION=""
BUILD_TARGET=""
INSTALL_PATH=""
PROXY_HOST=""
SCRIPT_NAME=$(basename "$0")

Okay="\033[32m[+]\033[0m"
ERR="\033[31m[-]\033[0m"

usage() {
    cat << EOF
    usage: $SCRIPT_NAME [options]

    Required options:
        -i. --install_path install path
        -v. --version binutils version
        -t. --build_target target architecture

    Optional options:
        -h. --help Display this help information

    Example:
        $SCRIPT_NAME -i /usr/local -v 2.38 -t aarch64-linux-gnu
        $SCRIPT_NAME --install_path /usr/local --version 2.38 --build_target aarch64-linux-gnu
        $SCRIPT_NAME --install_path /usr/local --proxy 192.168.1.123:4567 --version 2.38 --build_target aarch64-linux-gnu
EOF
}

TEMP=$(getopt -o i:v:t:p:h --long install_path:,version:,build_target:,proxy:,help -n '$SCRIPT_NAME' -- "$@")

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
        -p|--proxy)
            PROXY_HOST="$2"
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
    local proxy="-e use_proxy=yes -e https_proxy=https://$PROXY_HOST"
    mkdir -p source
    if [[ ! -f source/binutils-$BINUTILS_VERSION.tar.xz ]]; then
        echo "Download binutils source code: binutils-$BINUTILS_VERSION.tar.xz"
        if ! wget $proxy -q --show-progress -O "./source/binutils-$BINUTILS_VERSION.tar.xz" "https://sourceware.org/pub/binutils/releases/binutils-$BINUTILS_VERSION.tar.xz"; then
            echo -e "$ERR Error: Download failed !"
            exit 1
        fi
        echo -e "$Okay Download Successful !"
    fi
}

function build_binutils() {
    echo "  Install_Path: $INSTALL_PATH"
    echo "  Version: binutils-$BINUTILS_VERSION"
    echo "  BuildTarget: $BUILD_TARGET"
    if [[ ! -d binutils-$BINUTILS_VERSION ]]; then
        echo "Decompressing source code"
        if ! tar -xvf source/binutils-$BINUTILS_VERSION.tar.xz 2>&1 > tar-binutils-$BINUTILS_VERSION.log; then
            echo -e "$ERR Error: Decompressing failed !"
            exit 1
        fi
        echo -e "$Okay Decompressing Successful !"
    fi
    (
        mkdir -p binutils-$BINUTILS_VERSION/{build,logs} && cd binutils-$BINUTILS_VERSION/build
        
        echo "Compile environment detection"
        if ! ../configure --prefix=$INSTALL_PATH/$BINUTILS_VERSION --disable-gdb --disable-gdbserver --disable-weeror --disable-nls --target=$BUILD_TARGET > ../logs/configure.log 2>&1; then
            echo -e "$ERR Environmental failed !"
            exit 1
        fi
        echo -e "$Okay Compile environment Okay !"
        echo "Compiling"
        if ! (make -j$(nproc --all) > ../logs/build.log 2>&1 && make install > ../logs/install.log 2>&1); then
            echo -e "$ERR Error: Compile failed !"
            exit 1
        fi
        echo -e "$Okay Compile Successful !"
        make distclean > /dev/null 2>&1
        echo -e "$Okay Clean up !"
    )
}

download_binutils
build_binutils
