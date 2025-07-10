#!/bin/bash
#
# A script to verify if all nodes have actually started the run
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
# Date: Mon May 19 19:28:51 +04 2025
#

if [ $# -ne 1 ];  then
    echo "Usage: $0 <Slurm job output file>"
    exit 1
fi

OUTFILE=$1

for NODE in $( grep -e '^auh' ${OUTFILE} ); do
    if !  grep -q "${NODE}: checks DONE." ${OUTFILE}; then
        echo ${NODE}
    fi
done
