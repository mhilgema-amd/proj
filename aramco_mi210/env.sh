#!/usr/bin/bash
#
# Author:      Martin Hilgeman <martin.hilgeman@amd.com>
# Date:        04/10/2025 16:31:36
# Description: script the source the ROCm/MPI/UCX environment
#

PREFIX=/opt

#
# Application versions
#
CMAKE_VER=3.26.3
OPENMPI_VER=5.0.5
UCX_VER=1.16
UCC_VER=1.3
ROCM_VER=6.2.2

for APPLICATION in \
    cmake-${CMAKE_VER} \
    ompi-${OPENMPI_VER} \
    ucx-${UCX_VER} \
    ucc-${UCC_VER} \
    rocm-${ROCM_VER}; do
    #
    # PATH
    #
    if [ -d "${PREFIX}/${APPLICATION}/bin" ]; then
        export PATH=${PREFIX}/${APPLICATION}/bin:${PATH}
    fi

    #
    # LD_LIBRARY_PATH and LIBRARY_PATH
    #
    for LIB in lib lib64; do
        if [ -d "${PREFIX}/${APPLICATION}/${LIB}" ]; then
            if [ -n "${LD_LIBRARY_PATH}" ]; then
                export LD_LIBRARY_PATH=${PREFIX}/${APPLICATION}/${LIB}:${LD_LIBRARY_PATH}
            else
                export LD_LIBRARY_PATH=${PREFIX}/${APPLICATION}/${LIB}
            fi
            if [ -n "${LIBRARY_PATH}" ]; then
                export LIBRARY_PATH=${PREFIX}/${APPLICATION}/${LIB}:${LIBRARY_PATH}
            else
                export LIBRARY_PATH=${PREFIX}/${APPLICATION}/${LIB}
            fi
        fi
    done

    #
    # Include PATH
    #
    if [ -d "${PREFIX}/${APPLICATION}/include" ]; then
        if [ -n "${C_INCLUDE_PATH}" ]; then
            export C_INCLUDE_PATH=${PREFIX}/${APPLICATION}/include:${C_INCLUDE_PATH}
        else
            export C_INCLUDE_PATH=${PREFIX}/${APPLICATION}/include
        fi
        if [ -n "${CPLUS_INCLUDE_PATH}" ]; then
            export CPLUS_INCLUDE_PATH=${PREFIX}/${APPLICATION}/include:${CPLUS_INCLUDE_PATH}
        else
            export CPLUS_INCLUDE_PATH=${PREFIX}/${APPLICATION}/include
        fi
    fi
done

#
# Extra for ROCm
#
if [ -d "${PREFIX}/rocm-${ROCM_VER}" ]; then
    export ROCM_PATH=${PREFIX}/rocm-${ROCM_VER}
fi

#
# Extra for Open MPI
#
if [ -d "${PREFIX}/ompi-${OPENMPI_VER}" ]; then
    export MPI_HOME=${PREFIX}/ompi-${OPENMPI_VER}
fi
