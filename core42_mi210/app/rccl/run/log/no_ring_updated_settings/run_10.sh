#!/bin/bash
#
# Script to run the RCCL test 10 times.
#
HOST1=auh7-3b-gpu-006
HOST2=auh7-3b-gpu-008

if [ ! -d log/no_ring_updated_settings ]; then
	mkdir -p log/no_ring_updated_settings
fi

for RUN in $( seq 1 10 ); do
	./run_rccl.sh ${HOST1} ${HOST2} 2>&1 | tee log/no_ring_updated_settings/log.rccl.${HOST1}.${HOST2}.no_ring.run${RUN}
done
