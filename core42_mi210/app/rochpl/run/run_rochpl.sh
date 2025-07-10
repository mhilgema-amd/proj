#!/bin/bash

if [ $# -ne 1 ]; then
	echo "Usage: $0 <node>"
	exit 1
fi

HOST=$1

mpirun \
	-np 8 \
	-H ${HOST}:8 \
	affinity.sh \
	/mnt/vast01/apps/rocHPL/bin/rochpl \
	--NB 512 \
	-N 256000 \
	-P 2 \
	-Q 4 \
	-p 2 \
	-q 4 
