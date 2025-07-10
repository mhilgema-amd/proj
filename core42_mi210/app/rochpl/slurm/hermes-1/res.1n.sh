#!/bin/bash
#
# Scipt to output results in CSV format
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
#
echo -ne "NODE,RES,JOB\n"
for RUN in $( ls rochpl.g42.hermes-1.1n.* ); do
    NODE=$( echo ${RUN} | awk -F. '{print $8 }' )
    JOB=$( echo ${RUN} | awk -F. '{print $NF }' | sed 's/o//g' )
    if grep -aq '^Final Score:' ${RUN}; then
        RES=$( grep -a '^Final Score:' ${RUN} | awk '{print $3}' | awk '{printf "%.0f\n", $1}' )
        if [ ${RES} -lt 150000 ]; then
            RES="slow"
        fi
    else
        RES="failed"
    fi
    echo -ne "${NODE},${RES},${JOB}\n"
done
