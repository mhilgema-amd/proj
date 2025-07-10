#!/bin/bash
#

function setup_compiler ()
{
    #
    # Load modules
    #
    #
    case ${COMPILER} in
        aocc40)
            COMPILER_MODULE=amd/aocc/4.0.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        aocc32)
            COMPILER_MODULE=amd/aocc/3.2.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        aocc31)
            COMPILER_MODULE=amd/aocc/3.1.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        aocc30)
            COMPILER_MODULE=amd/aocc/3.0.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        aocc22)
            COMPILER_MODULE=amd/aocc/2.2.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}/aocc21/${MPIVER}
            fi
            ;;
        aocc21)
            COMPILER_MODULE=aocc/2.1.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}/aocc21/${MPIVER}
            fi
            ;;
        aocc20)
            COMPILER_MODULE=aocc/2.0.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}/aocc20/${MPIVER}
            fi
            ;;
        gcc131|gcc13u1)
            COMPILER_MODULE=gcc/13.1.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        gcc124|gcc12u4)
            COMPILER_MODULE=gcc/12.4.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        gcc123|gcc12u3)
            COMPILER_MODULE=gcc/12.3.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        gcc122|gcc12u2)
            COMPILER_MODULE=gcc/12.2.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        gcc121|gcc12u1)
            COMPILER_MODULE=gcc/12.1.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        gcc114|gcc11u4)
            COMPILER_MODULE=gcc/11.4.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        gcc113|gcc11u3)
            COMPILER_MODULE=gcc/11.3.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        gcc112|gcc11u2)
            COMPILER_MODULE=gcc/11.2.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        gcc104|gcc10u4)
            COMPILER_MODULE=gcc/10.4.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        gcc103|gcc10u3)
            COMPILER_MODULE=gcc/10.3.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        gcc102|gcc10u2)
            COMPILER_MODULE=gcc/10.2.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}/gcc102/${MPIVER}
            fi
            ;;
        gcc101|gcc10u1)
            COMPILER_MODULE=gcc/10.1.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}/gcc101/${MPIVER}
            fi
            ;;
        gcc93|gcc9u3)
            COMPILER_MODULE=gcc/9.3.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}/gcc93/${MPIVER}
            fi
            ;;
        gcc92|gcc9u2)
            COMPILER_MODULE=gcc/9.2.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}/gcc92/${MPIVER}
            fi
            ;;
        gcc91|gcc9u1)
            COMPILER_MODULE=gcc/9.1.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}/gcc91/${MPIVER}
            fi
            ;;
        gcc84|gcc8u4)
            COMPILER_MODULE=gcc/8.4.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}/gcc84/${MPIVER}
            fi
            ;;
        gcc83|gcc8u3)
            COMPILER_MODULE=gcc/8.3.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}/gcc83/${MPIVER}
            fi
            ;;
        intel23)
            COMPILER_MODULE=intel/oneAPI/2023.0.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        intel22)
            COMPILER_MODULE=intel/oneAPI/2022.3.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        intel21)
            COMPILER_MODULE=intel/oneAPI/2021.4.0
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        intel20)
            COMPILER_MODULE=intel/psxe/2020u4
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}
            fi
            ;;
        intel19)
            COMPILER_MODULE=intel/psxe/2019.3.199
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}/intel19/${MPIVER}
            fi
            ;;
        intel18)
            COMPILER_MODULE=intel/psxe/2018.4.274
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}/intel18/${MPIVER}
            fi
            ;;
        intel17)
            COMPILER_MODULE=intel/psxe/2017.8.262
            if [ ${MPI} = "openmpi" ]; then
                MPI_MODULE=${MPI}/intel17/${MPIVER}
            fi
            ;;
    esac

    if [ ${MPI} = "impi" ]; then
        MPI_MODULE=intel/mpi/2019u12
    fi
}
