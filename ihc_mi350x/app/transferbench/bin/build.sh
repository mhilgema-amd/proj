#!/usr/bin/bash
#
# Author:      Martin Hilgeman <martin.hilgeman@amd.com>
# Date:        07/10/2025 09:33:25
# Description: Babelstream build script
#

set -o pipefail

APP=transferbench
APP_NAME=TransferBench
PREFIX=${HOME}/app/${APP}
BRANCH=""
VERSION=""
ROCM=rocm700
SRC_DIR=${PREFIX}/git/${BRANCH}
WRK_DIR=${PREFIX}/work/${BRANCH}
BLD_DIR=${WRK_DIR}/build
INSTALL_PREFIX=/opt/${APP}/${ROCM}

function create_dirs ()
{
    for DIR in ${SRC_DIR} ${WRK_DIR} ${BLD_DIR}; do
        mkdir -p ${DIR} || exit 1
    done
}

#
# Clone repositories
#
function clone_repos ()
{
    cd ${SRC_DIR} || exit 1
    REPO="https://github.com/ROCm/TransferBench.git"
    if [ -n "${BRANCH}" ]; then
        git clone -b ${BRANCH} ${REPO} || exit 1
    else
        git clone ${REPO} || exit 1
    fi

    cd ${APP_NAME} || exit 1
    if [ -z "${VERSION}" ]; then
        VERSION="git_$( git rev-parse --short HEAD )"
    fi
}

function apply_patch ()
{
    cd ${WRK_DIR}/${APP_NAME} || exit 1

    #
    # Add support for ROCm 7.0.0 cmake build tools and MI350X
    #
    sed -i '/set(DEFAULT_GPUS/ifind_package(ROCmCMakeBuildTools)' CMakeLists.txt || exit 1
    sed -i '/gfx942/a\ \ \ \ \ \ gfx950' CMakeLists.txt || exit 1
}


#
# Setup work directory with source modifications (if any)
#
function setup_wrk_dirs ()
{
    cd ${WRK_DIR} || exit 1
    rsync -a ${SRC_DIR}/ . || exit 1
}

#
# Cmake
#
function setup_cmake ()
{
    cd ${BLD_DIR} || exit 1
    export CXX=hipcc
    cmake ${WRK_DIR}/${APP_NAME} \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}/${VERSION} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_COMPILER=${CXX} \
        2>&1 | tee log.cmake || exit 1
}

#
# Load ROCm environment
#
function load_rocm ()
{
    if module is-avail rocm; then
        module load rocm || exit 1
    fi

    if [ -z "${ROCM_PATH}" ]; then
        if [ -d /opt/rocm ]; then
            export ROCM_PATH=/opt/rocm
        else
            echo "ROCM_PATH is not set and /opt/rocm does not exist."
            exit 1
        fi
    fi
}

#
# Build source code
#
function build_src ()
{
    cd ${BLD_DIR} || exit 1
    make -j 32 2>&1 | tee log.make || exit 1
    sudo make install 2>&1 | tee log.make.install || exit 1

    #
    # Copy CFG files to the install directory
    #
    rsync -a examples ${INSTALL_PREFIX}/${VERSION}
}

create_dirs
clone_repos
setup_wrk_dirs
apply_patch
load_rocm
setup_cmake
build_src
