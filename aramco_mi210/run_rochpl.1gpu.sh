#!/bin/bash
#
# Author:      Martin Hilgeman <martin.hilgeman@amd.com>
# Date:        04/14/2025 10:33:01
# Description: Run script for rocHPL for Aramco POC on a single node
#
set -o pipefail
shopt -s expand_aliases
alias mytime='/usr/bin/time -f "Elapsed: %e  User: %U  System: %S  PageF: %F"'

#
# Script arguments
#
if [ $# -ne 1 ]; then
    echo "Usage $0: <GPU number>"
    exit 1
else
    MY_GPU="$1"
fi

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
NCPUS=8
NSOCK=2
NGPUS=1
PPN=${NGPUS}
NPES=$((NNODES * PPN))
export OMP_NUM_THREADS=$(( NCPUS / PPN ))

#
# 1 GCD configuration (MI210)
#
N=90112
NB=512
P=1
Q=1

#
# Affinity
#
START_CPU=$(( MY_GPU * NCPUS / PPN ))
END_CPU=$(( START_CPU + (NCPUS / PPN) - 1 ))
NUMA_DOMAIN=$( rocm-smi --showtoponuma | grep "GPU\[${MY_GPU}\].*Node:" | awk '{print $NF}' )
AFFINITY="numactl --all -C ${START_CPU}-${END_CPU} --cpubind=${NUMA_DOMAIN} --membind=${NUMA_DOMAIN}"

#
# Application setup
#
EXE=rochpl
EXE_ARGS="--NB ${NB} -N ${N} -P ${P} -Q ${Q}"

#
# Load environment
#
. env.sh || exit 1
MOD=${MODULE_PREFIX}/${APP}/${COMPILER}/${MPI}/${ROCM}/${VERSION}
if [ ! -e "${MOD}/bin/${EXE}" ]; then
    echo "$0: error: ${MOD}/bin/${EXE} not found"
    exit 1
fi
EXE="${MOD}/bin/${EXE}"

#
# MPI
#
MPIRUN=mpirun
MPI_ARGS="--bind-to none -x HIP_VISIBLE_DEVICES=${MY_GPU} -np ${NPES}"

#
# Start the run
#
RUNCMD="${MPIRUN} ${MPI_ARGS} ${AFFINITY} ${EXE} ${EXE_ARGS}"
echo ${RUNCMD}
mytime ${RUNCMD} 2>&1 | tee log.${APP}.$(hostname).${NNODES}n.${NCPUS}ppn.${NGPUS}gpus.${OMP_NUM_THREADS}t.${N}N.${NB}NB.${P}P.${Q}Q.gpu${MY_GPU}
