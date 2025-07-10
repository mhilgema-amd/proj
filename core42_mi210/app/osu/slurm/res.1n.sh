#!/bin/bash
#
# Scipt to output results in CSV format
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
#
echo -ne "NODE,RES,JOB\n"
for RUN in $( ls osu.g42.1n.128ppn.8gpu.auh7-3b-gpu-* ); do
    NODE=$( echo ${RUN} | awk -F. '{print $6 }' )
    JOB=$( echo ${RUN} | awk -F. '{print $NF }' | sed 's/o//g' )
    if grep -q '^4194304' ${RUN}; then
        RES=$( grep '^4194304' ${RUN} | awk '{print $2}' | sed 's/\.[0-9]*//g' )
        if [ ${RES} -lt 1000000 ]; then
            RES="slow"
        fi
    else
        RES="failed"
    fi
    echo -ne "${NODE},${RES},${JOB}\n"
done
