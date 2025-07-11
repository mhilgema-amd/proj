#!/bin/bash
#
# Run a CoralGemm benchmark
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
# Date: 07/11/2025
#

APP=coralgemm
ROCM=rocm700
VERSION=git_fc0df98
EXE=gemm
EXE_ARGS="R_64F R_64F R_64F R_64F OP_N OP_T 8640 8640 8640 8640 8640 8640 36 300"

MOD=${APP}/${ROCM}/${VERSION}
if module is-avail ${MOD}; then
    module load ${MOD}
else
    if [ ! -e $( which ${EXE}) ]; then
        echo "$0: Executable ${EXE} cannot be found. Exiting"
        exit 1
    fi
fi

#
# Perform the run
#
set -x
${EXE} ${EXE_ARGS} 2>&1 | tee stdout.${APP} || exit 1
set +x
