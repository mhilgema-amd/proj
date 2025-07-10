#!/bin/bash
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
# Date: Thu May 22 08:22:39 CET 2025
# Description: script to run minihpl and minihpcg prior to a big run
#
set -o pipefail

#
# Hostname
#
HOST=$( hostname -s )

#
# Set the quoting prefix
#
QUOTE="$0: ${HOST}:"

#
# Set the output files location
#
if [ -n "${SCR+x}" ]; then
  OUT_DIR="${SCR}"
else
  OUT_DIR="${SLURM_SUBMIT_DIR}"
fi

OUT_SUFFIX="${SLURM_JOB_ID}.${HOST}"
CHECK_LOG="${OUT_DIR}/stdout.do_checks.${OUT_SUFFIX}"

#
# Check to see if the environment is set properly
#
# All tools are in ${SCRIPT_DIR}. ${SCRIPT_DIR} must be set by job script
#
if [ ! -n "${SCRIPT_DIR+x}" ]; then
    echo "${QUOTE} SCRIPT_DIR variable has not been set. Exiting."
    exit 1
fi


#
# Run miniHPL and miniHPCG
#
echo -ne "${QUOTE} Starting checks ...\n" 2>&1 | tee ${CHECK_LOG}
for EXE in minihpcg minihpl; do
    if [ ! -f $( which ${EXE} ) ]; then
        echo "${QUOTE} binary cannot be found: ${EXE}. Exiting."
        exit 1
    fi
    OUT_FILE="${OUT_DIR}/checks.${EXE}.${OUT_SUFFIX}.log"

    ${EXE} > ${OUT_FILE} 2>&1  || exit 1

    #
    # Check result
    #
    if ! awk -f ${SCRIPT_DIR}/check_${EXE}.awk < ${OUT_FILE} | grep -q YES ; then
        echo "${QUOTE} check FAILED for ${EXE}. Exiting."
        #
        # Dump output more more time
        #
        awk -f ${SCRIPT_DIR}/check_${EXE}.awk < ${OUT_FILE}
        exit 1
   fi
done

echo -ne "${QUOTE} checks DONE.\n" 2>&1 | tee -a ${CHECK_LOG}
