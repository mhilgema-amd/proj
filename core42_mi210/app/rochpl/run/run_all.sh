#!/bin/bash
#
for NODE in $( cat ${HOME}/hostfiles/NNODES.txt ); do
    ./run_rochpl.sh ${NODE} 2>&1 | tee log.rochpl.${NODE} &
done
wait
