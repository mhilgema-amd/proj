#!/bin/bash

mpirun \
	--bind-to none \
	--mca pml ucx \
	--hostfile ${HOME}/hostfiles/hostfile_8gpu \
	-x UCX_TLS=self,sm,rocm_copy,rocm_ipc,ud_verbs \
	-x UCX_RNDV_THRESH=32768 \
	-x UCX_IB_GID_INDEX=3 \
	-x UCX_PROTO_INFO=n \
	-x UCX_PROTO_ENABLE=y \
	-x UCX_UNIFIED_MODE=y \
	-x UCX_ROCM_COPY_LAT=2e-6 \
	-x UCX_ROCM_IPC_MIN_ZCOPY=4096 \
	-x UCX_RNDV_SCHEME=get_zcopy \
	-np 256 \
	affinity.sh \
	/mnt/vast01/apps/rocHPL/bin/rochpl \
	--NB 512 \
	-N 1326592 \
	-P 16 \
	-Q 16 \
	-p 2 \
	-q 4
