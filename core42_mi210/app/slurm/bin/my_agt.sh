#!/bin/bash
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
# Date: Thu Mar 27 08:22:39 CET 2025
# Description: script to run AGT for GENE to capure PM logs
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
OUT_FILE="${OUT_DIR}/pmlog.${OUT_SUFFIX}.log"
AGT_LOG="${OUT_DIR}/stdout.agt.${OUT_SUFFIX}"

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
# Run AGT
#
EXE=/opt/software/eviden/AGT-internal/agt
if [ ! -f ${EXE} ]; then
    echo "${QUOTE} AGT cannot be found: ${EXE}. Exiting"
    exit 1
fi

if [ -z "${AGT_JOBNAME}" ]; then
    echo "${QUOTE} AGT_JOBNAME variable is not set. Exiting."
    exit 1
fi

echo -ne "${QUOTE} Starting PM log ...\n" 2>&1 | tee ${AGT_LOG}
sudo ${EXE} \
    -unilog=PM \
    -i=10,11 \
    -unilogallgroups \
    -unilogperiod=50 \
    -unilogstopcheck \
    -unilognoesckey \
    -unilogstopcheck \
    -unilogoutput=${OUT_FILE} \
    >> ${AGT_LOG} < /dev/null 2>&1 &
MY_PID=$!

while [ -f ${SCR}/${AGT_JOBNAME} ]; do
    sleep 5
done

BASE_EXE=$( basename ${EXE} )
echo -ne "${QUOTE} killing AGT processes with PPID ${MY_PID} ...\n" 2>&1 | tee ${AGT_LOG}
sudo pkill -P ${MY_PID} -f ${BASE_EXE}

#
# Check if processes are gone
#
if $( ps -ef | grep -q "${BASE_EXE} " | grep -qv grep ); then  
    sleep 5
    echo -ne "${QUOTE} 2nd attempt killing AGT process by name ${BASE_EXE} ...\n" 2>&1 | tee ${AGT_LOG}
    sudo pkill -9 -f ${BASE_EXE}
else
    echo -ne "${QUOTE} DONE killing AGT processes.\n" 2>&1 | tee ${AGT_LOG}
fi
