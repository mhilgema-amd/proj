#!/usr/bin/bash
#
# Author:      Martin Hilgeman <martin.hilgeman@amd.com>
# Date:        2025-03-06 14:20
# Description: Open MPI build script with all depen
#

set -o pipefail

#
# Versions
#
HWLOC_VERSION=2.12.1
XPMEM_VERSION=git_3bcab55
UCX_VERSION=1.18.1
UCC_VERSION=git_42d5236
OPENMPI_VERSION=5.0.8
ROCM=rocm700
ROCM_VERSION=7.0.0

#
# Default paths
#
PREFIX=${HOME}/app/openpi/openmpi-build
SRCDIR=${PREFIX}/src
WRKDIR=${PREFIX}/work
INSTALL_PREFIX=/opt


########## DO NOT EDIT BELOW THIS LINE ##########

#
# Load environment modules
#
function load_modules ()
{
    module purge
    module load rocm/${ROCM_VERSION}

    if [ ! -n "${ROCM_PATH}" ]; then
        echo "ROCM_PATH is not set. Exiting."
        exit 1
    fi
}

#
# Unpack source code
#
function unpack_source ()
{
    cd ${BUILD_DIR} || exit 1
    tar zxf ${SRCDIR}/${APP}-${APP_VERSION}.tar.gz
}

#
# Unpack git code
#
function unpack_git ()
{
    cd ${BUILD_DIR} || exit 1
    rsync -a ${SRCDIR}/${APP} .
}

#
# Create build directory
#
function create_build_dir ()
{
    if [ -d ${BUILD_DIR} ]; then
        rm -rf ${BUILD_DIR}
    fi
    mkdir -p ${BUILD_DIR} || exit 1
}


function create_dirs ()
{
    if [ ! -d ${SRCDIR} ]; then
        mkdir -p ${SRCDIR} || exit 1
    fi

    if [ ! -d ${WRKDIR} ]; then
        mkdir -p ${WRKDIR} || exit 1
    fi
}

function build_hwloc ()
{
    APP=hwloc
    APP_VERSION=${HWLOC_VERSION}
    MAJOR_VERSION=$( echo ${APP_VERSION} | cut -d. -f1,2 )

    BUILD_DIR=${WRKDIR}/${APP}/${APP_VERSION}

    create_build_dir

    #
    # Get source code
    #
    cd ${SRCDIR} || exit 1
    wget https://download.open-mpi.org/release/${APP}/v${MAJOR_VERSION}/${APP}-${APP_VERSION}.tar.gz || exit 1

    #
    # Unpack source code
    #
    cd ${BUILD_DIR} || exit 1
    tar zxf ${SRCDIR}/${APP}-${APP_VERSION}.tar.gz

    #
    # Build source code
    #
    cd ${BUILD_DIR}/${APP}-${APP_VERSION} || exit 1
    mkdir build && cd build || exit 1

    ../configure \
        --prefix=${INSTALL_PREFIX}/${APP}/${APP_VERSION} \
        2>&1 | tee log.configure || exit 1

    make -j 8 2>&1 | tee log.make || exit 1
    sudo make install 2>&1 | tee log.make.install || exit 1
}

function build_xpmem ()
{
    APP=xpmem
    APP_VERSION=${XPMEM_VERSION}

    BUILD_DIR=${WRKDIR}/${APP}/${APP_VERSION}

    create_build_dir

    #
    # Get source code
    #
    cd ${SRCDIR} || exit 1
    git clone https://github.com/hpc/xpmem.git

    unpack_git

    #
    # Build source code
    #
    cd ${BUILD_DIR}/${APP} || exit 1
    ./autogen.sh

    #
    # We can't build xpmem out of tree
    #
    #mkdir build && cd build || exit 1

    ./configure \
        --prefix=${INSTALL_PREFIX}/${APP}/${APP_VERSION} \
        2>&1 | tee log.configure || exit 1

    make -j 8 2>&1 | tee log.make || exit 1
    sudo make install 2>&1 | tee log.make.install || exit 1
}

function build_ucx()
{
    APP=ucx
    APP_VERSION=${UCX_VERSION}

    BUILD_DIR=${WRKDIR}/${APP}/${APP_VERSION}

    create_build_dir

    #
    # Get source code
    #
    cd ${SRCDIR} || exit 1
    wget https://github.com/openucx/${APP}/archive/refs/tags/v${APP_VERSION}.tar.gz -O ${APP}-${APP_VERSION}.tar.gz || exit 1

    #
    # Unpack source code
    #
    unpack_source

    #
    # Build source code
    #
    cd ${BUILD_DIR}/${APP}-${APP_VERSION} || exit 1
    ./autogen.sh

    mkdir build && cd build || exit 1

    ../contrib/configure-release \
        --prefix=${INSTALL_PREFIX}/${APP}/${ROCM}/${APP_VERSION} \
        --with-rocm=${ROCM_PATH} \
        --with-xpmem=${INSTALL_PREFIX}/xpmem/${XPMEM_VERSION} \
        2>&1 | tee log.configure || exit 1

    make -j 8 2>&1 | tee log.make || exit 1
    sudo make install 2>&1 | tee log.make.install || exit 1
}

function build_ucc()
{
    APP=ucc
    APP_VERSION=${UCC_VERSION}

    BUILD_DIR=${WRKDIR}/${APP}/${APP_VERSION}

    create_build_dir

    #
    # Get source code
    #
    cd ${SRCDIR} || exit 1
    git clone https://github.com/openucx/${APP}.git || exit 1

    #
    # Unpack source code
    #
    unpack_git

    #
    # Build source code
    #
    cd ${BUILD_DIR}/${APP} || exit 1
    ./autogen.sh

    mkdir build && cd build || exit 1

    ../configure \
        --prefix=${INSTALL_PREFIX}/${APP}/${ROCM}/${APP_VERSION} \
        --with-ucx=${INSTALL_PREFIX}/ucx/${ROCM}/${UCX_VERSION} \
        --with-rocm=${ROCM_PATH} \
        --with-rccl=${ROCM_PATH} \
        2>&1 | tee log.configure || exit 1

    make -j 8 2>&1 | tee log.make || exit 1
    sudo make install 2>&1 | tee log.make.install || exit 1
}


function build_openmnpi (
    APP=openmpi
    APP_VERSION=${OPENMPI_VERSION}
    MAJOR_VERSION=$( echo ${APP_VERSION} | cut -d. -f1,2 )

    BUILD_DIR=${WRKDIR}/${APP}/${APP_VERSION}

    create_build_dir

    #
    # Get source code
    #
    cd ${SRCDIR} || exit 1
    wget https://download.open-mpi.org/release/open-mpi/v${MAJOR_VERSION}/${APP}-${APP_VERSION}.tar.gz || exit 1

    unpack_source

    #
    # Build source code
    #
    cd ${BUILD_DIR}/${APP}-${APP_VERSION} || exit 1
    mkdir build && cd build || exit 1

    #
    # Fix for undefined reference to `ucc_init_version' when running UCC test
    # in configure script
    export LD_LIBRARY_PATH=${INSTALL_PREFIX}/ucx/${ROCM}/${UCX_VERSION}/lib:${LD_LIBRARY_PATH}

    ../configure \
            --prefix=${INSTALL_PREFIX}/${APP}/${ROCM}/${APP_VERSION} \
            --enable-mpi1-compatibility \
            --enable-pmix-binaries \
            --with-pmix=internal \
            --with-hwloc=${INSTALL_PREFIX}/hwloc/${HWLOC_VERSION} \
            --with-slurm \
            --with-munge=/usr \
            --with-munge-libdir=/usr/lib/x86_64-linux-gnu \
            --with-ucx=${INSTALL_PREFIX}/ucx/${ROCM}/${UCX_VERSION} \
            --with-cma \
            --with-xpmem=${INSTALL_PREFIX}/xpmem/${XPMEM_VERSION} \
            --with-rocm=${ROCM_PATH} \
            --with-ucc=${INSTALL_PREFIX}/ucc/${ROCM}/${UCC_VERSION} \
        2>&1 | tee log.configure || exit 1

    make -j 2>&1 | tee log.make || exit 1
    sudo make install 2>&1 | tee log.make.install || exit 1

)

load_modules
create_dirs
build_hwloc
build_xpmem
build_ucx
build_ucc
build_openmnpi
