#!/bin/bash
#

function init_application ()
{
    APP=gromacs
    VERSION=2023
    SUFFIX=
    BUILD=
    NSOCK=2
    MPI=openmpi
    COMPILER=intel22
    PREFIX=${HOME}/app/${APP}/work/${VERSION}/${BUILD}
    INPD=${HOME}/app/${APP}/inp
    INP=
    EXE=gmx_mpi
    EXE_ARGS=""
    EXTRA_OPTION=""
    TEXT_EXTRA_OPTION1="<GROMACS number of steps>"
    TEXT_EXTRA_OPTION2="<not used>           "
    TEXT_EXTRA_OPTION3="<not used>           "
    EXTRA_OPTION1=10000
    GROMACS_NSTEPS=${EXTRA_OPTION1}
}

function post_application ()
{
	cat >> .slurmjobscript.$$ <<- EOF
		#
		# GROMACS post processing
		#
		#

	EOF
}

function extra_setup ()
{
    #
    # Build application options
    #
    EXE_ARGS="${EXE_ARGS} mdrun -s ${INP}.tpr"
    EXE_ARGS="${EXE_ARGS} -dlb yes"
    EXE_ARGS="${EXE_ARGS} -v"
    EXE_ARGS="${EXE_ARGS} -resethway"
    EXE_ARGS="${EXE_ARGS} -noconfout"
    EXE_ARGS="${EXE_ARGS} -nsteps ${GROMACS_NSTEPS}"

}
