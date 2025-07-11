#!/usr/bin/bash
#
# Author:      Martin Hilgeman <martin.hilgeman@amd.com>
# Date:        07/11/2025 13:26:25
# Description: rocHPL build script
#

set -o pipefail

APP=rochpl
APP_NAME=rocHPL
PREFIX=${HOME}/app/${APP}
BRANCH=""
VERSION=""
ROCM=rocm700
MPI=openmpi
SRC_DIR=${PREFIX}/git/${BRANCH}
WRK_DIR=${PREFIX}/work/${BRANCH}
BLD_DIR=${PREFIX}/build/${BRANCH}
INSTALL_PREFIX=/opt/${APP}/${MPI}/${ROCM}

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
    REPO="https://github.com/ROCm/rocHPL.git"
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
    export CXX=mpicxx
    cmake ${WRK_DIR}/${APP_NAME} \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}/${VERSION} \
        -DCMAKE_BUILD_TYPE=Release \
        -DROCM_PATH=${ROCM_PATH} \
        -DROCBLAS_PATH=${ROCM_PATH} \
        -DCMAKE_PREFIX_PATH=${ROCM_PATH} \
        -DHPL_MPI_DIR=${MPI_HOME} \
        -DHPL_PROGRESS_REPORT=ON \
        -DHPL_DETAILED_TIMING=ON \
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
# Load Open MPI
#
function load_mpi ()
{
    if module is-avail ${MPI}/${ROCM} j; then
        module load ${MPI}/${ROCM}
    fi

    if [ -z "${MPI_HOME}" ]; then
        echo "load_openmpi: MPI_HOME variable not set. Exiting."
        exit 1
    fi
}

#
# Build source code
#
function build_src ()
{
    cd ${BLD_DIR} || exit 1
    make -j 32 2>&1 | tee log.make || exit 1
    sudo -E make install 2>&1 | tee log.make.install || exit 1
}

create_dirs
clone_repos
setup_wrk_dirs
load_rocm
load_mpi
setup_cmake
build_src
