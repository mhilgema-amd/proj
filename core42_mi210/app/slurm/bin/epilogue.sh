#!/bin/bash
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
# Date: Thu Mar 27 08:22:39 CET 2025
# Description: epilogue script for GENE runs to set things like:
#     - CPU boost frequency
#     - GPU SCLK
#     - Number of GPU hardware queues
#
# to their normal values
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
# Reset Boost to on
#
echo -ne "${QUOTE} Resetting Boost ...\n" 2>&1 | tee -a ${OUT_CLOCK}
BOOST_EN=1
sudo ${SCRIPT_DIR}/boost-en.sh >> ${OUT_CLOCK} 2>&1 || exit 1
echo -ne "${QUOTE} BOOST_EN is set to ${BOOST_EN}\n" 2>&1 | tee -a ${OUT_CLOCK}

#
# Reset the CPU frequency
#
echo -ne "${QUOTE} Resetting CPU frequency ...\n" 2>&1 | tee -a ${OUT_CLOCK}
CPU_CLK_MAX="3700MHz"
sudo cpupower -c all frequency-set --max "${CPU_CLK_MAX}" >> ${OUT_CLOCK} 2>&1 || exit 1
cpupower -c all frequency-info >> ${OUT_CLOCK} 2>&1 || exit 1
echo -ne "${QUOTE} DONE resetting CPU frequency.\n" 2>&1 | tee -a ${OUT_CLOCK}

#
# Reset the GPU clock
#
echo -ne "${QUOTE} Resetting GPU clock ...\n" 2>&1 | tee -a ${OUT_CLOCK}
sudo /opt/rocm/bin/amd-smi reset --clocks >> ${OUT_CLOCK} 2>&1 || exit 1
/opt/rocm/bin/rocm-smi --showsclkrange >> ${OUT_CLOCK} 2>&1 || exit 1
echo -ne "${QUOTE} DONE resetting GPU clock.\n" 2>&1 | tee -a ${OUT_CLOCK}

#
# End of script
#
echo -ne "\n${QUOTE} Epilogue DONE.\n"
exit 0
