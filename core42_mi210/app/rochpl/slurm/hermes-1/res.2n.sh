#!/bin/bash
#
# Scipt to output results in CSV format
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
#
echo -ne "NODE 1,NODE 2,RES,JOB\n"
for RUN in $( ls rochpl.g42.hermes-1.2n.* ); do
    NODE1=$( grep -a -A2 'Node list' 2> /dev/null ${RUN} | sed -n '2p' )
    NODE2=$( grep -a -A2 'Node list' 2> /dev/null ${RUN} | sed -n '3p' )
    JOB=$( echo ${RUN} | awk -F. '{print $NF }' | sed 's/o//g' )
    if grep -aq '^Final Score:' ${RUN}; then
        RES=$( grep -a '^Final Score:' ${RUN} | awk '{print $3}' | awk '{printf "%.0f\n", $1}' )
        if [ ${RES} -lt 280000 ]; then
            RES="slow"
        fi
    else
        RES="failed"
    fi
    echo -ne "${NODE1},${NODE2},${RES},${JOB}\n"
done
