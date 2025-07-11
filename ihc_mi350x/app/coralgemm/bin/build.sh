#!/usr/bin/bash
#
# Author:      Martin Hilgeman <martin.hilgeman@amd.com>
# Date:        07/11/2025 12:35:25
# Description: CoralGemm build script
#

set -o pipefail

APP=coralgemm
APP_NAME=CoralGemm
PREFIX=${HOME}/app/${APP}
BRANCH=""
VERSION=""
ROCM=rocm700
SRC_DIR=${PREFIX}/git/${BRANCH}
WRK_DIR=${PREFIX}/work/${BRANCH}
BLD_DIR=${PREFIX}/build/${BRANCH}
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
    REPO="https://github.com/AMD-HPC/CoralGemm.git"
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
        -DHIP_PLATFORM=amd \
        -DCMAKE_PREFIX_PATH=${ROCM_PATH} \
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
}

#
# Install the binary. As CoralGemm does not have a 'make install' defined,
# we have to copy it manually
#
function install_bin ()
{
    EXE=gemm
    if [ -e ${BLD_DIR}/${EXE} ]; then
        sudo mkdir -p ${INSTALL_PREFIX}/${VERSION}/bin
        sudo cp ${BLD_DIR}/${EXE} ${INSTALL_PREFIX}/${VERSION}/bin || exit 1
        echo "${APP} binary ${EXE} installed."
    else
        echo "${APP} binary ${EXE} cannot be found. Exiting."
        exit 1
    fi
}

create_dirs
clone_repos
setup_wrk_dirs
load_rocm
setup_cmake
build_src
install_bin
