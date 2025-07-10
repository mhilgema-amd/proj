#!/bin/bash

if [ $# -ne 1 ]; then
	echo "USage: $0 <node>"
	exit 1
fi

HOST=$1

mpirun \
	-np 8 \
	-H ${HOST}:8 \
	affinity-intranet.sh \
	/mnt/vast01/rccl/rccl-tests/bin/all_reduce_perf \
	-b 8 \
	-e 4G \
	-f 2 \
	-g 1
