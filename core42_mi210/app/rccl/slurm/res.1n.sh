#!/bin/bash
#
# Scipt to output results in CSV format
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
#
echo -ne "NODE,RES,JOB\n"
for RUN in $( ls all_reduce_perf.g42.3b.1n.* ); do
    NODE=$( echo ${RUN} | awk -F. '{print $7 }' )
    JOB=$( echo ${RUN} | awk -F. '{print $NF }' | sed 's/o//g' )
    if grep -aq 'Out of bounds values : 0 OK' ${RUN}; then
        RES=$( grep -a '2147483648' ${RUN} | awk '{print $12}' )
        INT_RES=$( echo ${RES} | awk '{printf "%.0f\n", $1}' )
        if [ ${INT_RES} -lt 30 ]; then
            RES="slow"
        fi
    else
        RES="failed"
    fi
    echo -ne "${NODE},${RES},${JOB}\n"
done
