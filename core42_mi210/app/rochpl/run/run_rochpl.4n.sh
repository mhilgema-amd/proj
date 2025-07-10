#!/bin/bash

if [ $# -ne 4 ]; then
	echo "Usage: $0 <node 1> <node 2> <node 3> <node 4>"
	exit 1
fi

HOST1=$1
HOST2=$2
HOST3=$3
HOST4=$4

mpirun \
	--bind-to none \
	--mca pml ucx \
	-H ${HOST1}:8,${HOST2}:8,${HOST3}:8,${HOST4}:8 \
	-x UCX_TLS=self,sm,rocm_copy,rocm_ipc,ud_verbs \
	-x UCX_RNDV_THRESH=32768 \
	-x UCX_IB_GID_INDEX=3 \
	-x UCX_PROTO_INFO=y \
	-x UCX_PROTO_ENABLE=y \
	-x UCX_UNIFIED_MODE=y \
	-x UCX_ROCM_COPY_LAT=2e-6 \
	-x UCX_ROCM_IPC_MIN_ZCOPY=4096 \
	-x UCX_RNDV_SCHEME=get_zcopy \
	-np 32 \
	affinity.sh \
	/mnt/vast01/apps/rocHPL/bin/rochpl \
	--NB 512 \
	-N 511488 \
	-P 4 \
	-Q 8 \
	-p 2 \
	-q 4
