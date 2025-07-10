#!/bin/bash
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
# Date: Thu Mar 27 08:22:39 CET 2025
# Description: prologue script for GENE runs to set things like:
#     - CPU boost frequency
#     - GPU SCLK
#     - Number of GPU hardware queues
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

OUT_CLOCK="${OUT_DIR}/clock-settings.${OUT_SUFFIX}.log"

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
# Check for these variables (have to be set in the Slurm job script
#
#for VAR in SCLK_MAX \
#           SCLK_MAX \
#           CPU_CLK_MAX \
#           BOOST_EN; do
#       if ! $( env | grep -q ${VAR} ); then
#           echo "${QUOTE} variable ${VAR} not found. Exiting."
#           exit 1
#       fi
#done

#
# Number of GPU hardware queues
#
#if [ -n "${GPU_MAX_HW_QUEUES}" ]; then
#    echo -ne "${QUOTE} GPU GPU_MAX_HW_QUEUES is set to ${GPU_MAX_HW_QUEUES}\n" 2>&1 | tee -a ${OUT_CLOCK}
#fi

#
# Toggle Boost on/off
#
#echo -ne "${QUOTE} Setting Boost ...\n" 2>&1 | tee -a ${OUT_CLOCK}
#if [ "${BOOST_EN}" -eq 0 ]; then
#    sudo ${SCRIPT_DIR}/boost-dis.sh >> ${OUT_CLOCK} 2>&1 || exit 1
#else
#    sudo ${SCRIPT_DIR}/boost-en.sh >> ${OUT_CLOCK} 2>&1 || exit 1
#fi
#echo -ne "${QUOTE} BOOST_EN is set to ${BOOST_EN}\n" 2>&1 | tee -a ${OUT_CLOCK}

#
# Set the CPU frequency
#
#echo -ne "${QUOTE} Setting CPU frequency ...\n" 2>&1 | tee -a ${OUT_CLOCK}
#sudo cpupower -c all frequency-set --max "${CPU_CLK_MAX}" >> ${OUT_CLOCK} 2>&1 || exit 1
#cpupower -c all frequency-info >> ${OUT_CLOCK} 2>&1 || exit 1
#echo -ne "${QUOTE} DONE setting CPU frequency.\n" 2>&1 | tee -a ${OUT_CLOCK}

#
# Set the GPU clock
#
#echo -ne "${QUOTE} Setting GPU clock ...\n" 2>&1 | tee -a ${OUT_CLOCK}
#sudo /opt/rocm/bin/amd-smi set -L sclk min "${SCLK_MIN}" >> ${OUT_CLOCK} 2>&1 || exit 1
#sudo /opt/rocm/bin/amd-smi set -L sclk max "${SCLK_MAX}" >> ${OUT_CLOCK} 2>&1 || exit 1
#/opt/rocm/bin/rocm-smi --showsclkrange >> ${OUT_CLOCK} 2>&1 || exit 1
#echo -ne "${QUOTE} DONE setting GPU clock.\n" 2>&1 | tee -a ${OUT_CLOCK}

#
# Reset the GPUs
#
echo -ne "${QUOTE} Resetting GPUs ...\n" 2>&1 | tee -a ${OUT_CLOCK}
for DEV in {0..7}; do rocm-smi --gpureset -d ${DEV} >> ${OUT_CLOCK} 2>&1 & done; wait
echo -ne "${QUOTE} DONE resetting GPUs.\n" 2>&1 | tee -a ${OUT_CLOCK}

#
# End of script
#
echo -ne "\n${QUOTE} Prologue DONE.\n"
exit 0
