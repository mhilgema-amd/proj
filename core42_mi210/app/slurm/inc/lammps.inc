#!/bin/bash
#

function init_application ()
{
    APP=lammps
    VERSION=19Mar2020
    BUILD=
    NSOCK=2
    MPI=openmpi
    COMPILER=intel19
    PREFIX=${HOME}/app/${APP}/work/${VERSION}/${BUILD}
    INPD=${HOME}/app/${APP}/inp
    INP=lj
    EXE=lmp
    EXE_ARGS="-var x 8 -var y 8 -var z 4 -var r 1000"
    EXTRA_OPTION="omp|opt|intel"
    TEXT_EXTRA_OPTION1="LAMMPS USER <omp|opt|intel>"
    TEXT_EXTRA_OPTION2="<not used>           "
    TEXT_EXTRA_OPTION3="<not used>           "
}

function post_application ()
{
    echo
}

function extra_setup ()
{
    echo
}
