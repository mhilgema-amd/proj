#!/bin/bash
#
# Scipt to output results in CSV format
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
#
echo -ne "NODE 1,NODE 2,RES,JOB\n"
for RUN in $( ls osu.g42.2n.128ppn.8gpu.auh7-3b-gpu-* ); do
    NODE1=$( grep -a -A2 'Node list' 2> /dev/null ${RUN} | sed -n '2p' )
    NODE2=$( grep -a -A2 'Node list' 2> /dev/null ${RUN} | sed -n '3p' )
    JOB=$( echo ${RUN} | awk -F. '{print $NF }' | sed 's/o//g' )
    if grep -aq '^2097152' 2> /dev/null ${RUN}; then
        RES=$( grep -a '^2097152' ${RUN} | awk '{print $2}' | sed 's/\.[0-9]*//g' )
        if [ ${RES} -lt 45000 ]; then
            RES="slow"
        fi
    else
        RES="failed"
    fi
    echo -ne "${NODE1},${NODE2},${RES},${JOB}\n"
done
