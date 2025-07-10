#!/bin/bash
#
# Script to run the RCCL test 10 times.
#
HOST=auh7-3b-gpu-003

LOGDIR=intranet

if [ ! -d log/${LOGDIR} ]; then
	mkdir -p log/${LOGDIR}
fi

for RUN in $( seq 1 10 ); do
	./run_rccl-intranet.sh ${HOST} 2>&1 | tee log/${LOGDIR}/log.rccl.${HOST}.intranet.run${RUN}
done
