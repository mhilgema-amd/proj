#!/bin/bash
#

function init_application ()
{
    APP=vasp
    VERSION=5.4.4
    BUILD=
    NSOCK=2
    MPI=openmpi
    COMPILER=intel19
    PREFIX=${HOME}/app/${APP}/work/${VERSION}/${BUILD}
    INPD=${HOME}/app/${APP}/inp
    INP=
    EXE=vasp_std
    EXE_ARGS=""
    EXTRA_OPTION=""
    TEXT_EXTRA_OPTION1="VASP type <gam|std|ncl>"
    TEXT_EXTRA_OPTION2="<VASP KPAR value>    "
    TEXT_EXTRA_OPTION3="<not used>           "
}

function post_application ()
{
	cat >> .slurmjobscript.$$ <<- EOF
		echo
		echo "VASP Elapsed time"
		echo "================="
		grep Elapsed \${SCR}/OUTCAR
		grep LOOP+ \${SCR}/OUTCAR
	EOF
}

function extra_setup ()
{
    case "${PARTITION}" in
        6248)
            NCORE=10
            NPAR=$(( PPN / 4 ))
            ;;
        7443)
            NCORE=24
            NPAR=$(( PPN / 2 ))
            ;;
        7513|7543|9354|9354-gen4|9354-gen5)
            NCORE=10
            NPAR=$(( PPN / 2 ))
            ;;
        7702|7713|7373X|7763)
            NCORE=32
            NPAR=$(( PPN / 4 ))
            ;;
        *)
            NCORE=16
            NPAR=4
            ;;
    esac


	cat >> .slurmjobscript.$$ <<- EOF
	#
	# Set optimal KPAR option
	#
	HAVE_KPAR=0
	if [ x${EXTRA_OPTION2} != x ]; then
	    KPAR=${EXTRA_OPTION2}
	    grep -q KPAR INCAR > /dev/null 2>&1
	    if [ \$? -eq 0 ]; then
	        sed "s/\\(KPAR\\).*=.*[0-9]*\$/\\1 = \${KPAR}/" < INCAR > INCAR.\$\$
	        mv INCAR.\$\$ INCAR
	    else
	        echo "KPAR = \${KPAR}" >> INCAR
	    fi
	    HAVE_KPAR=1
	fi
	
	EOF


	cat >> .slurmjobscript.$$ <<- EOF
	#
	# Set optimal NPAR option
	#
	HAVE_NPAR=0
	grep -q NPAR INCAR > /dev/null 2>&1
	if [ \$? -eq 0 ]; then
	    sed "s/\\(NPAR\\).*=.*[0-9]*\$/\\1 = ${NPAR}/" < INCAR > INCAR.\$\$
	    mv INCAR.\$\$ INCAR
	    HAVE_NPAR=1
	fi

	EOF

	cat >> .slurmjobscript.$$ <<- EOF
	#
	# Set optimal NCORE option
	#
	if [ \${HAVE_NPAR} -eq 0 ]; then
	    NCORE=${NCORE}
	    if [ \${HAVE_KPAR} -eq 1 ]; then
	        NCORE=\$( echo "${NPES} / \${KPAR}" | bc )
	    fi
	    grep -q NCORE INCAR > /dev/null 2>&1
	    if [ \$? -eq 0 ]; then
	        sed "s/\\(NCORE\\).*=.*[0-9]*\$/\\1 = \${NCORE}/" < INCAR > INCAR.\$\$
	        mv INCAR.\$\$ INCAR
	    else
	        echo "NCORE = \${NCORE}" >> INCAR
	    fi
	fi

	EOF


	cat >> .slurmjobscript.$$ <<- EOF
	#
	# Set optimal NSIM option, which is 32 in most cases
	#
	NSIM=32
	grep -q NSIM INCAR > /dev/null 2>&1
	if [ \$? -eq 0 ]; then
	    sed "s/\\(NSIM\\).*=.*[0-9]*\$/\\1 = \${NSIM}/" < INCAR > INCAR.\$\$
	    mv INCAR.\$\$ INCAR
	else
	    echo "NSIM = \${NSIM}" >> INCAR
	fi

	EOF
}
