#!/bin/bash

if [ $# -ne 2 ]; then
	echo "Usage: $0 <node 1> <node 2>"
	exit 1
fi

HOST1=$1
HOST2=$2

#	-x UCX_IB_GID_INDEX=3 \
#	-x UCX_PROTO_INFO=n \
#	-x UCX_PROTO_ENABLE=y \
#	-x UCX_UNIFIED_MODE=y \
#	-x UCX_ROCM_COPY_LAT=2e-6 \
#	-x UCX_ROCM_IPC_MIN_ZCOPY=4096 \
#	-x UCX_RNDV_SCHEME=get_zcopy \
#	-x UCX_RNDV_THRESH=32768 \

mpirun \
	--bind-to none \
	--mca pml ucx \
	-x UCX_TLS=self,sm,rocm_copy,rocm_ipc,ud_verbs \
	-np 16 \
	-H ${HOST1}:8,${HOST2}:8 \
	affinity.sh \
	/mnt/vast01/apps/rocHPL/bin/rochpl \
	--NB 512 \
	-N 361472 \
	-P 4 \
	-Q 4 \
	-p 2 \
	-q 4
