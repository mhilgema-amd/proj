#!/bin/bash
#
set -o pipefail

ROCM=6.3.3
PREFIX=${HOME}/martinh/app/rochpl
SRCDIR=${PREFIX}/git/rocHPL
WRKDIR=${PREFIX}/work

if [ -d ${WRKDIR}/build ]; then rm -rf ${WRKDIR}/build; fi
mkdir ${WRKDIR}/build && cd ${WRKDIR}/build

cmake ${SRCDIR} \
    -DCMAKE_INSTALL_PREFIX=${HOME}/martinh/opt/rochpl/rocm633/git_2812c08 \
    -DHPL_MPI_DIR=${MPI_HOME} \
    -DROCM_PATH=/opt/rocm-${ROCM} \
    -DROCBLAS_PATH=/opt/rocm-${ROCM} \
    -DCMAKE_BUILD_TYPE=Release \
    -DHPL_PROGRESS_REPORT=ON \
    -DHPL_DETAILED_TIMING=ON \
    2>&1 | tee log.cmake || exit 1

make -j 2>&1 | tee log.make
make install 2>&1 | tee log.make.install
