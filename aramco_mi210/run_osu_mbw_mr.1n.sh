#!/bin/bash
#
# Author:      Martin Hilgeman <martin.hilgeman@amd.com>
# Date:        04/14/2025 10:33:01
# Description: Run script for OSU message rate benchmark 
#              for Aramco POC on a single node
#
set -o pipefail
shopt -s expand_aliases
alias mytime='/usr/bin/time -f "Elapsed: %e  User: %U  System: %S  PageF: %F"'

#
# Default environment variables
#
APP=osu
COMPILER=gcc114
MPI=openmpi
ROCM=rocm622
VERSION=7.4

MODULE_PREFIX=${HOME}/martinh/opt
APP_PREFIX="/opt/${APP}-${VERSION}/libexec/osu-micro-benchmarks/mpi"

#
# Node setup
#
NNODES=1
NCPUS=64
NSOCK=2
NGPUS=8
PPN=${NCPUS}
NPES=$((NNODES * PPN))
export OMP_NUM_THREADS=$(( NCPUS / PPN ))

#
# Affinity
#
AFFINITY="--bind-to core --map-by core:PE=${OMP_NUM_THREADS} --report-bindings"

#
# Application setup
#
EXE=osu_mbw_mr
EXE_ARGS="D D"

#
# Load environment
#
. env.sh || exit 1
for DIR in collective congestion one-sided pt2pt startup; do
    export PATH=${APP_PREFIX}/${DIR}:${PATH}
done
if [ ! -e $( which ${EXE} )]; then
    echo "$0: error: ${EXE} not found"
    exit 1
fi

#
# MPI
#
MPIRUN=mpirun
MPI_ARGS="${MPI_ARGS} --mca pml ucx" 
MPI_ARGS="${MPI_ARGS} -x UCX_PROTO_ENABLE=y"
MPI_ARGS="${MPI_ARGS} -x UCX_PROTO_INFO=n"
MPI_ARGS="${MPI_ARGS} -x UCX_PROTO_ENABLE=y"
MPI_ARGS="${MPI_ARGS} -x UCX_UNIFIED_MODE=y"
MPI_ARGS="${MPI_ARGS} -x UCX_ROCM_COPY_LAT=2e-6"
MPI_ARGS="${MPI_ARGS} -x UCX_ROCM_IPC_MIN_ZCOPY=4096"
MPI_ARGS="${MPI_ARGS} -x UCX_RNDV_SCHEME=get_zcopy"
MPI_ARGS="${MPI_ARGS} -x UCX_RNDV_THRESH=32768"
MPI_ARGS="${MPI_ARGS} -np ${NPES}"


#
# Start the run
#
RUNCMD="${MPIRUN} ${MPI_ARGS} ${AFFINITY} ${EXE} ${EXE_ARGS}"
echo ${RUNCMD}
mytime ${RUNCMD} 2>&1 | tee log.${APP}.$(hostname).${NNODES}n.${NCPUS}ppn.${NGPUS}gpus.${OMP_NUM_THREADS}t.${N}N.${NB}NB.${P}P.${Q}Q.gpu${MY_GPU}
