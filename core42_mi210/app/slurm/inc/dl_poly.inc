#!/bin/bash
#

function init_application ()
{
    APP=dl_poly
    VERSION=4.0.7
    SUFFIX=
    BUILD=
    NSOCK=2
    MPI=openmpi
    COMPILER=intel21
    PREFIX=${HOME}/app/${APP}/work/${VERSION}/${BUILD}
    INPD=${HOME}/app/${APP}/inp
    INP=
    EXE=DLPOLY.Z
    EXE_ARGS=""
    EXTRA_OPTION=""
    TEXT_EXTRA_OPTION1="<not used>           "
    TEXT_EXTRA_OPTION2="<not used>           "
    TEXT_EXTRA_OPTION3="<not used>           "
}

function post_application ()
{
	cat >> .slurmjobscript.$$ <<- EOF
		#
		# Get the DL_POLY elapsed time from the OUTPUT file
		#
		#
		WALL=\$( grep 'time elapsed since job start:' \${SCR}/OUTPUT | tail -1 | awk '{print \$6}' )

		STEPS=\$( grep -B 5 'rolling' \${SCR}/OUTPUT | tail -5 | head -1 | awk '{print \$1}' )
		INIT_TIME=\$( grep -B 2 'rolling' \${SCR}/OUTPUT | head -2 | head -1 | awk '{print \$1}' )
		CPU_TIME=\$( grep -B 5 'rolling' \${SCR}/OUTPUT | tail -5 | tail -3 | head -1 | awk '{print \$1}' )
		STEPS_SEC=\$( echo "scale=3; \${STEPS} / \${CPU_TIME}" | bc )
		echo "DL_POLY init time: \${INIT_TIME}"
		echo "DL_POLY cpu time: \${CPU_TIME}"
		echo "DL_POLY number of steps: \${STEPS}"
		echo "DL_POLY MD steps / second: \${STEPS_SEC}"
		echo "DL_POLY wall clock time: \${WALL}"
	EOF
}

function extra_setup ()
{
    echo
}
