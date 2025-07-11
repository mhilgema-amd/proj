#!/usr/bin/bash
#
# Author:      Martin Hilgeman <martin.hilgeman@amd.com>
# Date:        07/11/2025 13:26:25
# Description: USO build script
#

set -o pipefail

APP=osu
APP_NAME=osu-micro-benchmarks
PREFIX=${HOME}/app/${APP}
BRANCH=""
VERSION="7.5.1"
ROCM=rocm700
MPI=openmpi
SRC_DIR=${PREFIX}/src/${BRANCH}
WRK_DIR=${PREFIX}/work/${BRANCH}
BLD_DIR=${PREFIX}/build/${BRANCH}
INSTALL_PREFIX=/opt/${APP}/${MPI}/${ROCM}

function create_dirs ()
{
    for DIR in ${SRC_DIR} ${WRK_DIR}; do
        mkdir -p ${DIR} || exit 1
    done
}

#
# Clone repositories
#
function clone_repos ()
{
    cd ${SRC_DIR} || exit 1
    REPO="https://mvapich.cse.ohio-state.edu/download/mvapich/${APP_NAME}-${VERSION}.tar.gz"
    wget ${REPO} -O ${APP_NAME}-${VERSION}.tar.gz

    cd ${APP_NAME}-${VERSION} || exit 1
}


#
# Setup work directory with source modifications (if any)
#
function setup_wrk_dirs ()
{
    cd ${WRK_DIR} || exit 1
    tar zxf ${SRC_DIR}/${APP_NAME}-${VERSION}.tar.gz || exit 1
}

#
# Cmake
#
function setup_make ()
{
    cd ${BLD_DIR} || exit 1
    CC=mpicc CXX=mpicxx \
    ${WRK_DIR}/${APP_NAME}/configure  \
        --prefix=${INSTALL_PREFIX}/${VERSION} \
        --with-hip=${ROCM_PATH} \
        --enable-rocm=${ROCM_PATH} \
        --with-rccl=${ROCM_PATH} \
        --enable-rcclomb \
        2>&1 | tee log.configure || exit 1
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
setup_make
build_src
