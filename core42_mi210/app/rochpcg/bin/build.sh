#!/bin/bash
#
set -o pipefail

ROCM=6.3.3
PREFIX=${HOME}/martinh/app/rochpcg
SRCDIR=${PREFIX}/git/rocHPCG
WRKDIR=${PREFIX}/work

if [ -d ${WRKDIR}/build ]; then rm -rf ${WRKDIR}/build; fi
mkdir ${WRKDIR}/build && cd ${WRKDIR}/build

cmake ${SRCDIR} \
    -DCMAKE_INSTALL_PREFIX=${HOME}/martinh/opt/rochpcg/rocm633/git_38aa7b3 \
    -DHPCG_MPI=ON \
    -DHPCG_MPI_DIR=${MPI_HOME} \
    -DGPU_AWARE_MPI=ON \
    -DHPCG_OPENMP=ON \
    -DROCM_PATH=/opt/rocm-${ROCM} \
    -DCMAKE_BUILD_TYPE=Release \
    -DHPCG_DETAILED_TIMING=ON \
    2>&1 | tee log.cmake || exit 1

make -j 2>&1 | tee log.make
make install 2>&1 | tee log.make.install
