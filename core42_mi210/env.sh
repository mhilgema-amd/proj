#!/bin/bash

PREFIX=${HOME}/martinh/opt
APP_DIR=/mnt/vast01/apps

function add_cmake ()
{
    export PATH=${PREFIX}/cmake/3.31.7/bin:${PATH}
}

function add_rccl ()
{
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
}

function add_mpi ()
{
    APP=ompi
    VERSION=5.0.5
    APP_PREFIX=${APP_DIR}/${APP}-${VERSION}

    export MPI_HOME=${APP_PREFIX}
    export PATH=${APP_PREFIX}/bin:${PATH}

    if [ -z "${LD_LIBRARY_PATH}" ]; then
        export LD_LIBRARY_PATH=${APP_PREFIX}/lib
    else
        export LD_LIBRARY_PATH=${APP_PREFIX}/lib:${LD_LIBRARY_PATH}
    fi

    if [ -z "${LIBRARY_PATH}" ]; then
        export LIBRARY_PATH=${APP_PREFIX}/lib
    else
        export LIBRARY_PATH=${APP_PREFIX}/lib:${LIBRARY_PATH}
    fi

    if [ -z "${C_INCLUDE_PATH}" ]; then
        export C_INCLUDE_PATH=${APP_PREFIX}/include
    else
        export C_INCLUDE_PATH=${APP_PREFIX}/include:${C_INCLUDE_PATH}
    fi

    if [ -z "${CPLUS_INCLUDE_PATH}" ]; then
        export CPLUS_INCLUDE_PATH=${PREFIX}/include
    else
        export CPLUS_INCLUDE_PATH=${PREFIX}/include:${CPLUS_INCLUDE_PATH}
    fi
}

function add_rochpl ()
{
    APP=rocHPL
    VERSION=
    APP_PREFIX=${APP_DIR}/${APP}

    export PATH=${APP_PREFIX}/bin:${PATH}
}

function add_rccl_tests ()
{
    APP=rccl-tests
    VERSION=
    APP_PREFIX=/mnt/vast01/rccl/${APP}

    export PATH=${APP_PREFIX}/bin:${PATH}
}

function add_osu ()
{
    APP=osu
    VERSION=
    APP_PREFIX=/mnt/vast01/validation/${APP}/libexec/osu-micro-benchmarks/mpi

    export PATH=${APP_PREFIX}/collective:${PATH}
    export PATH=${APP_PREFIX}/congestion:${PATH}
    export PATH=${APP_PREFIX}/one-sided:${PATH}
    export PATH=${APP_PREFIX}/pt2pt:${PATH}
    export PATH=${APP_PREFIX}/startup:${PATH}
}


#
# Main
#
add_cmake
add_mpi
add_rochpl
add_rccl
add_rccl_tests
add_osu
