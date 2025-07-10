#!/bin/bash

if [ $# -ne 2 ]; then
	echo "USage: $0 <node 1> <node 2>"
	exit 1
fi

HOST1=$1
HOST2=$2

mpirun \
	-x NCCL_DEBUG=INFO \
	-np 16 \
	-H ${HOST1}:8,${HOST2}:8 \
	affinity.works.sh \
	/mnt/vast01/rccl/rccl-tests/bin/all_reduce_perf \
	-b 8 \
	-e 4G \
	-f 2 \
	-g 1
