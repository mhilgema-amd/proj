#!/usr/bin/bash
#
# Author:      Martin Hilgeman <martin.hilgeman@amd.com>
# Date:        12/03/2024 10:41:23
# Description: Shuffle a list of nodes and come up with
#              all possible combinations.
#

touch LIST.txt
for SEQ in $(seq 1 2000); do
    NODE1=$(shuf NNODES.txt | sed -n '1p')
    NODE2=$(shuf NNODES.txt | sed -n '2p')
    if [ ${NODE1} != ${NODE2} ]; then
        COMBINED="${NODE1},${NODE2}"
        if ! grep -q ${COMBINED} LIST.txt; then
            echo ${COMBINED} >> LIST.txt
        fi
    fi
done

COUNT=0
for NODES in $( cat LIST.txt ); do
    sbatch -w ${NODES} run_rochpl.2n.8ppn.8gpu.hermes-1.pre-test.slm

    #
    # Don't overload Slurm
    #
    COUNT=$(( COUNT + 1 ))
    if [ $(( COUNT % 100 )) -eq 0 ]; then
        sleep 2
    fi
done
