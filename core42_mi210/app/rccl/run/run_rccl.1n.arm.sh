#!/bin/bash

mpirun \
	-np 8 \
	affinity.arm.sh \
	/mnt/vast01/rccl/rccl-tests/bin/all_reduce_perf \
	-b 8 \
	-e 4G \
	-f 2 \
	-g 1
