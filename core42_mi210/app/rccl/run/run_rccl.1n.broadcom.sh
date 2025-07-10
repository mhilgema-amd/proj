#!/bin/bash

mpirun \
	-np 8 \
	affinity.broadcom.sh \
	/mnt/vast01/rccl/rccl-tests/bin/all_reduce_perf \
	-b 8 \
	-e 4G \
	-f 2 \
	-g 1
