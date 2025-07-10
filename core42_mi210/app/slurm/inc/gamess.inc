#!/bin/bash
#

function init_application ()
{
    APP=gamess
    VERSION=30092019R2
    BUILD=04_gddi
    NSOCK=2
    MPI=openmpi
    MPIVER=4.0.5
    COMPILER=intel20
    PREFIX=${HOME}/app/${APP}/work/${VERSION}/${BUILD}
    INPD=${HOME}/app/${APP}/inp
    INP=quinone.inp
    EXE=
    EXE_ARGS=
    EXTRA_OPTION1="01"
    TEXT_EXTRA_OPTION1="GAMESS binary VERNO  "
    TEXT_EXTRA_OPTION2="<not used>           "
    TEXT_EXTRA_OPTION3="<not used>           "
}

function post_application ()
{
    echo
}

function extra_setup ()
{
	cat >> .slurmjobscript.$$ <<- EOF
	#
	# Remove existing SYSV semaphores and shared memory segments prior to the run
	#
	#
	for NNODE in \$(scontrol show hostnames); do
	    ssh \${NNODE} ipcrm -a < /dev/null & 
	done
	wait

	EOF
}
