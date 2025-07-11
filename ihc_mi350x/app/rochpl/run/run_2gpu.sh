#!/bin/bash
#
# Run a rocHPL benchmark
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
# Date: 07/11/2025
#

APP=rochpl
ROCM=rocm700
MPI=openmpi
VERSION=git_2812c08
EXE=rochpl
EXE_ARGS="--NB 512 -N 248832 -P 1 -Q 2 -p 1 -q 2"
AFFINITY="${HOME}/bin/affinity.sh"

NPES=2

MPIRUN=mpirun
MPI_ARGS="${MPI_ARGS} --bind-to none"
MPI_ARGS="${MPI_ARGS} --mca pml ucx"
#MPI_ARGS="${MPI_ARGS} --hostfile ${HOME}/hostfiles/hostfile_8gpu"
#MPI_ARGS="${MPI_ARGS} -x UCX_TLS=self,sm,rocm_copy,rocm_ipc,ud_verbs"
#MPI_ARGS="${MPI_ARGS} -x UCX_TLS=self,sm,rocm_copy,rocm_ipc"
#MPI_ARGS="${MPI_ARGS} -x UCX_RNDV_THRESH=32768"
#MPI_ARGS="${MPI_ARGS} -x UCX_IB_GID_INDEX=3"
#MPI_ARGS="${MPI_ARGS} -x UCX_PROTO_INFO=n"
#MPI_ARGS="${MPI_ARGS} -x UCX_PROTO_ENABLE=y"
#MPI_ARGS="${MPI_ARGS} -x UCX_UNIFIED_MODE=y"
#MPI_ARGS="${MPI_ARGS} -x UCX_ROCM_COPY_LAT=2e-6"
#MPI_ARGS="${MPI_ARGS} -x UCX_ROCM_IPC_MIN_ZCOPY=4096"
#MPI_ARGS="${MPI_ARGS} -x UCX_RNDV_SCHEME=get_zcopy"
MPI_ARGS="${MPI_ARGS} -np ${NPES}"

MOD=${APP}/${MPI}/${ROCM}/${VERSION}
if module is-avail ${MOD}; then
    module load ${MOD}
else
    if [ ! -e $( which ${EXE} ) ]; then
        echo "$0: Executable ${EXE} cannot be found. Exiting"
        exit 1
    fi
fi

#
# Perform the run
#
set -x
${MPIRUN} ${MPI_ARGS} ${AFFINITY} ${EXE} ${EXE_ARGS} 2>&1 | tee stdout.${APP}.${NPES}gpu || exit 1
mv HPL.out HPL.out.${NPES}gpu
set +x
