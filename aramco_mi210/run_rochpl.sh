#!/usr/bin/bash
#
# Author:      Martin Hilgeman <martin.hilgeman@amd.com>
# Date:        04/14/2025 10:33:01
# Description: Run script for rocHPL for Aramco POC
#
set -o pipefail
shopt -s expand_aliases
alias mytime='/usr/bin/time -f "Elapsed: %e  User: %U  System: %S  PageF: %F"'

#
# Default environment variables
#
APP=rochpl
COMPILER=gcc114
MPI=openmpi
ROCM=rocm622
VERSION=git_03730d0

MODULE_PREFIX=${HOME}/martinh/opt

#
# Node setup
#
NNODES=1
NCPUS=64
NSOCK=2
NGPUS=8
PPN=${NGPUS}
NPES=$((NNODES * PPN))
export OMP_NUM_THREADS=$(( NCPUS / PPN ))

#
# 8 GCD configuration (MI210)
#
N=256000
NB=512
P=2
Q=4

#
# Application setup
#
EXE=run_rochpl
EXE_ARGS="--NB ${NB} -N ${N} -P ${P} -Q ${Q}"

#
# Load environment
#
MOD=${MODULE_PREFIX}/${APP}/${COMPILER}/${MPI}/${ROCM}/${VERSION}
if [ ! -e "${MOD}/${EXE}" ]; then
    echo "$0: error: ${MOD}/${EXE} not found"
    exit 1
fi
EXE=${MOD}/${EXE}

#
# MPI
#
MPIRUN=mpirun
MPI_ARGS="-n ${NPES}"

#
# Start the run
#
RUNCMD="${MPIRUN} ${MPI_ARGS} ${EXE} ${EXE_ARGS}"
echo ${RUNCMD}
mytime ${RUNCMD} 2>&1 | tee log.${APP}.$(hostname).${NNODES}n.${NCPUS}ppn.${NGPUS}gpus.${OMP_NUM_THREADS}t.${N}.N.${NB}.NB.${P}.P.${Q}.Q
