#!/bin/bash

PREFIX=${HOME}/martinh/opt

export PATH=${PREFIX}/cmake/3.31.7/bin:${PATH}

if [ -z "${LD_LIBRARY_PATH}" ]; then
    export LD_LIBRARY_PATH=${PREFIX}/rccl/rocm633/2.25.1/lib
else
    export LD_LIBRARY_PATH=${PREFIX}/rccl/rocm633/2.25.1/lib:${LD_LIBRARY_PATH}
fi

if [ -z "${LIBRARY_PATH}" ]; then
    export LIBRARY_PATH=${PREFIX}/rccl/rocm633/2.25.1/lib
else
    export LIBRARY_PATH=${PREFIX}/rccl/rocm633/2.25.1/lib:${LIBRARY_PATH}
fi

if [ -z "${C_INCLUDE_PATH}" ]; then
    export C_INCLUDE_PATH=${PREFIX}/rccl/rocm633/2.25.1/include
else
    export C_INCLUDE_PATH=${PREFIX}/rccl/rocm633/2.25.1/include:${C_INCLUDE_PATH}
fi


if [ -z "${CPLUS_INCLUDE_PATH}" ]; then
    export CPLUS_INCLUDE_PATH=${PREFIX}/rccl/rocm633/2.25.1/include
else
    export CPLUS_INCLUDE_PATH=${PREFIX}/rccl/rocm633/2.25.1/include:${CPLUS_INCLUDE_PATH}
fi
