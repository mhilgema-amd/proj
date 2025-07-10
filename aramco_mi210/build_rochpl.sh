#!/usr/bin/bash
#
# Author:      Martin Hilgeman <martin.hilgeman@amd.com>
# Date:        04/14/2025 05:47:51
# Description: rocHPL build script
#
set -o pipefail

# Default environment variables
APP=rochpl
COMPILER=gcc114
MPI=openmpi
ROCM=rocm622
VERSION=git_03730d0

PREFIX=${HOME}/app/${APP}
SRCDIR=${PREFIX}/git
WRKDIR=${PREFIX}/work
BLDDIR=${WRKDIR}/build
INSTALL_PREFIX=${HOME}/opt/${APP}/${COMPILER}/${MPI}/${ROCM}/${VERSION}

# load modules
. ${WRKDIR}/env.sh || exit 1

## Cmake configuration
if [ -d ${BLDDIR} ]; then rm -rf ${BLDDIR}; fi
mkdir -p ${BLDDIR} && cd ${BLDDIR} || exit 1

cmake ${SRCDIR}/rocHPL \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DHPL_MPI_DIR=${MPI_HOME} \
    -DROCM_PATH=${ROCM_PATH} \
    -DROCBLAS_PATH=${ROCM_PATH} \
    -DCMAKE_BUILD_TYPE=Release \
    -DHPL_PROGRESS_REPORT=ON \
    -DHPL_DETAILED_TIMING=ON \
    2>&1 | tee log.cmake || exit 1

# Run 'make' and install
make -j32 2>&1 | tee log.make || exit 1
make install 2>&1 | tee log.make.install || exit 1
