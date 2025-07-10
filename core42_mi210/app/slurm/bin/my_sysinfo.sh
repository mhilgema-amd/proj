#!/bin/bash
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
# Date: Thu Mar 27 08:22:39 CET 2025
# Description: script to dump system info
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
OUT_FILE="${OUT_DIR}/sysinfo.${OUT_SUFFIX}"

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
# Start of collection
#
echo "${QUOTE} Starting collection ..." 2>&1 | tee -a ${OUT_FILE}

#
# dmidecode
#
EXE=dmidecode
EXE_ARGS="-t bios"
if [ ! -f $( which ${EXE} ) ]; then
    echo "${QUOTE} ${EXE} cannot be found." 2>&1 | tee -a ${OUT_FILE}
else
    echo "############### ${EXE} ###############" >> ${OUT_FILE} 2>&1
    ${EXE} ${EXE_ARGS} >> ${OUT_FILE} 2>&1
    echo -ne "\n\n" >> ${OUT_FILE} 2>&1
fi

#
# ROCm version
#
if [ -n "${ROCM_PATH+x}" ];  then
    echo "############### ROCm ###############" >> ${OUT_FILE} 2>&1
    cat ${ROCM_PATH}/.info/version >> ${OUT_FILE} 2>&1
    echo -ne "\n\n" >> ${OUT_FILE} 2>&1
fi

#
# rocminfo
#
EXE=rocminfo
EXE_ARGS=
if [ ! -f $(which ${EXE} ) ]; then
    echo "${QUOTE} ${EXE} cannot be found." 2>&1 | tee -a ${OUT_FILE}
else
    echo "############### ${EXE} ###############" >> ${OUT_FILE} 2>&1
    ${EXE} ${EXE_ARGS} >> ${OUT_FILE} 2>&1
    echo -ne "\n\n" >> ${OUT_FILE} 2>&1
fi

#
# rocm-smi
#
EXE=rocm-smi
EXE_ARGS=
if [ ! -f $( which ${EXE} ) ]; then
    echo "${QUOTE} ${EXE} cannot be found." 2>&1 | tee -a ${OUT_FILE}
else
    echo "############### ${EXE} ###############" >> ${OUT_FILE} 2>&1
    ${EXE} ${EXE_ARGS} >> ${OUT_FILE} 2>&1
    echo -ne "\n\n" >> ${OUT_FILE} 2>&1
fi

#
# numastat
#
EXE=numastat
EXE_ARGS=
if [ ! -f $( which ${EXE} ) ]; then
    echo "${QUOTE} ${EXE} cannot be found." 2>&1 | tee -a ${OUT_FILE}
else
    echo "############### ${EXE} ###############" >> ${OUT_FILE} 2>&1
    ${EXE} ${EXE_ARGS} >> ${OUT_FILE} 2>&1
    echo -ne "\n\n" >> ${OUT_FILE} 2>&1
fi

#
# Memory usage
#
EXE=free
EXE_ARGS="-m"
if [ ! -f $( which ${EXE} ) ]; then
    echo "${QUOTE} ${EXE} cannot be found." 2>&1 | tee -a ${OUT_FILE}
else
    echo "############### ${EXE} ###############" >> ${OUT_FILE} 2>&1
    ${EXE} ${EXE_ARGS} >> ${OUT_FILE} 2>&1
    echo -ne "\n\n" >> ${OUT_FILE} 2>&1
fi

#
# rdma
#
EXE=rdma
EXE_ARGS1="link show"
EXE_ARGS2="dev"
if [ ! -f $( which ${EXE} ) ]; then
    echo "${QUOTE} ${EXE} cannot be found." 2>&1 | tee -a ${OUT_FILE}
else
    echo "############### ${EXE} ###############" >> ${OUT_FILE} 2>&1
    ${EXE} ${EXE_ARGS1} >> ${OUT_FILE} 2>&1
    ${EXE} ${EXE_ARGS2} >> ${OUT_FILE} 2>&1
    echo -ne "\n\n" >> ${OUT_FILE} 2>&1
fi

#
# Kernel settings
#
EXE=sysctl
EXE_ARGS="-a"
if [ ! -f $( which ${EXE} ) ]; then
    echo "${QUOTE} ${EXE} cannot be found." 2>&1 | tee -a ${OUT_FILE}
else
    echo "############### ${EXE} ###############" >> ${OUT_FILE} 2>&1
    ${EXE} ${EXE_ARGS} >> ${OUT_FILE} 2>&1
    echo -ne "\n\n" >> ${OUT_FILE} 2>&1
fi

#
# Transparent huge pages
#
EXE=THP
echo "############### ${EXE} ###############" >> ${OUT_FILE} 2>&1
cat /sys/kernel/mm/transparent_hugepage/enabled >> ${OUT_FILE} 2>&1
grep thp /proc/vmstat >> ${OUT_FILE} 2>&1
echo -ne "\n\n" >> ${OUT_FILE} 2>&1

#
# Stop of collection
#
echo "${QUOTE} Stopping collection ..." 2>&1 | tee -a ${OUT_FILE}
