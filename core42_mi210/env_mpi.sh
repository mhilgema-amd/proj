#!/bin/bash

PREFIX=${HOME}/martinh/opt
APP_DIR=/mnt/vast01/apps
ROCM=rocm633

function add_path ()
{
    if [ -n "$1" ]; then
        export PATH=${APP_PREFIX}/$1:${PATH}
    else
        export PATH=${APP_PREFIX}/bin:${PATH}
    fi
}

function add_library_path ()
{
    if [ -z "${LD_LIBRARY_PATH}" ]; then
        if [ -n "$1" ]; then
            export LD_LIBRARY_PATH=${APP_PREFIX}/$1
        else
            export LD_LIBRARY_PATH=${APP_PREFIX}/lib
        fi
    else
        if [ -n "$1" ]; then
            export LD_LIBRARY_PATH=${APP_PREFIX}/$1:${LD_LIBRARY_PATH}
        else
            export LD_LIBRARY_PATH=${APP_PREFIX}/lib:${LD_LIBRARY_PATH}
        fi
    fi

    if [ -z "${LIBRARY_PATH}" ]; then
        if [ -n "$1" ]; then
            export LIBRARY_PATH=${APP_PREFIX}/$1
        else
            export LIBRARY_PATH=${APP_PREFIX}/lib
        fi
    else
        if [ -n "$1" ]; then
            export LIBRARY_PATH=${APP_PREFIX}/$1:${LIBRARY_PATH}
        else
            export LIBRARY_PATH=${APP_PREFIX}/lib:${LIBRARY_PATH}
        fi
    fi
}

function add_include_path ()
{
    if [ -z "${C_INCLUDE_PATH}" ]; then
        if [ -n "$1" ]; then
            export C_INCLUDE_PATH=${APP_PREFIX}/$1
        else
            export C_INCLUDE_PATH=${APP_PREFIX}/include
        fi
    else
        export C_INCLUDE_PATH=${APP_PREFIX}/include:${C_INCLUDE_PATH}
    fi

    if [ -z "${CPLUS_INCLUDE_PATH}" ]; then
        if [ -n "$1" ]; then
            export CPLUS_INCLUDE_PATH=${APP_PREFIX}/$1
        else
            export CPLUS_INCLUDE_PATH=${APP_PREFIX}/include
        fi
    else
        if [ -n "$1" ]; then
            export CPLUS_INCLUDE_PATH=${APP_PREFIX}/$1:${CPLUS_INCLUDE_PATH}
        else
            export CPLUS_INCLUDE_PATH=${APP_PREFIX}/include:${CPLUS_INCLUDE_PATH}
        fi
    fi
}

function add_pkg_config_path ()
{
    if [ -z "${PKG_CONFIG_PATH}" ]; then
        if [ -n "$1" ]; then
            export PKG_CONFIG_PATH=${APP_PREFIX}/$1
        else
            export PKG_CONFIG_PATH=${APP_PREFIX}/lib/pkgconfig
        fi
    else
        if [ -n "$1" ]; then
            export PKG_CONFIG_PATH=${APP_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}
        else
            export PKG_CONFIG_PATH=${APP_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}
        fi
    fi
}


function add_cmake_prefix_path ()
{
    if [ -z "${CMAKE_PREFIX_PATH}" ]; then
        if [ -n "$1" ]; then
            export CMAKE_PREFIX_PATH=${APP_PREFIX}/lib/cmake
        else
            export CMAKE_PREFIX_PATH=${APP_PREFIX}/lib/cmake
        fi
    else
        if [ -n "$1" ]; then
            export CMAKE_PREFIX_PATH=${APP_PREFIX}/lib/cmake:${CMAKE_PREFIX_PATH}
        else
            export CMAKE_PREFIX_PATH=${APP_PREFIX}/lib/cmake:${CMAKE_PREFIX_PATH}
        fi
    fi
}

function add_cmake ()
{
    APP=cmake
    VERSION=3.31.7
    APP_PREFIX=${PREFIX}/${APP}/${VERSION}

    add_path
}

function add_rccl ()
{
    APP=rccl
    VERSION=2.25.1
    APP_PREFIX=${PREFIX}/${APP}/${ROCM}/${VERSION}

    add_library_path
    add_include_path
}

function add_rccl-tests ()
{
    APP=rccl-tests
    APP_PREFIX=/mnt/vast01/rccl/${APP}

    add_path
}

function add_hwloc ()
{
    APP=hwloc
    VERSION=2.12.0
    APP_PREFIX=${PREFIX}/${APP}/${VERSION}

    add_path
    add_library_path
    add_include_path
    add_pkg_config_path
}

function add_ucx ()
{
    APP=ucx
    VERSION=1.18.1
    APP_PREFIX=${PREFIX}/${APP}/${ROCM}/${VERSION}

    add_path
    add_library_path
    add_include_path
    add_pkg_config_path
    add_cmake_prefix_path
}

function add_ucc ()
{
    APP=ucc
    VERSION=git_6235b32
    APP_PREFIX=${PREFIX}/${APP}/${ROCM}/${VERSION}

    add_path
    add_library_path
    add_include_path
    add_pkg_config_path
    add_cmake_prefix_path
}

function add_xpmem ()
{
    APP=xpmem
    VERSION=git_3bcab55
    APP_PREFIX=${PREFIX}/${APP}/${VERSION}

    add_library_path
    add_include_path
    add_pkg_config_path
}

function add_mpi ()
{
    APP=openmpi
    VERSION=5.0.7
    APP_PREFIX=${PREFIX}/${APP}/${ROCM}/${VERSION}

    export MPI_HOME=${APP_PREFIX}

    add_path
    add_library_path
    add_include_path
    add_pkg_config_path
}

function add_rochpl ()
{
    APP=rochpl
    VERSION=git_2812c08
    APP_PREFIX=${PREFIX}/${APP}/${ROCM}/${VERSION}

    add_path
}

function add_rochpcg ()
{
    APP=rochpcg
    VERSION=git_38aa7b3
    APP_PREFIX=${PREFIX}/${APP}/${ROCM}/${VERSION}

    add_path
}

function add_minihpl ()
{
    APP=minihpl
    VERSION=git_8f5f175
    APP_PREFIX=${PREFIX}/${APP}/${ROCM}/${VERSION}

    add_path
}

function add_minihpcg ()
{
    APP=minihpcg
    VERSION=git_c851a77
    APP_PREFIX=${PREFIX}/${APP}/${ROCM}/${VERSION}

    add_path
}

function add_agfhc ()
{
    APP=agfhc
    VERSION=1.21.2
    APP_PREFIX=${PREFIX}/${APP}/${VERSION}

    add_path ${APP}
    add_path transferbench
    add_path firestorm/usr/bin
    add_path firexs/usr/bin
    add_library_path firexs/usr/lib
    add_library_path firexs/usr/lib
    add_library_path rocsift/usr/lib

    export TXB_PATH=${APP_PREFIX}/transferbench
    export FIREXS_PATH=${APP_PREFIX}/firexs
}

#
# Main
#
add_cmake
add_hwloc
add_xpmem
add_ucx
add_ucc
add_mpi
add_rccl
add_rccl-tests
add_rochpl
add_rochpcg
add_minihpl
add_minihpcg
add_agfhc
