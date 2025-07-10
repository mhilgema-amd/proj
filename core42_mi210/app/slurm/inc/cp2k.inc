#!/bin/bash
#

function init_application ()
{
    APP=cp2k
    VERSION=7.1
    if [ ${HAVE_AMD} -gt 0 ]; then
        SUFFIX=
    else
        SUFFIX=-avx512
    fi
    BUILD=
    NSOCK=2
    MPI=impi
    COMPILER=gcc93
    PREFIX=${HOME}/app/${APP}/work/${VERSION}/${BUILD}
    INPD=${HOME}/app/${APP}/inp
    INP=
    EXE=cp2k.psmp
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
		# CP2k post-processing
		#
		#

	EOF
}

function extra_setup ()
{
    #
    # Build application options
    #
    EXE_ARGS="${EXE_ARGS} -i ${INP}.inp"

    if [ ${ARCH} = "amd" ]; then
		cat >> .slurmjobscript.$$ <<- EOF
			#
			# Enable AVX2 code path in Intel MKL for AMD EPYC processors
			#
			export MKL_DEBUG_CPU_TYPE=5

		EOF
    fi

	cat >> .slurmjobscript.$$ <<- EOF
		#
		# Increase the OMP stack size
		#
		export KMP_STACKSIZE=256M

	EOF
}
