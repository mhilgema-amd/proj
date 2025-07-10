#!/bin/bash
#

function init_application ()
{
    APP=qe
    VERSION=6.7
    SUFFIX=
    BUILD=
    NSOCK=2
    MPI=openmpi
    COMPILER=intel19
    PREFIX=${HOME}/app/${APP}/work/${VERSION}/${BUILD}
    INPD=${HOME}/app/${APP}/inp
    INP=
    EXE=pw.x
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
		# Convert the PWSCF wall clock time from 00m00.00s to seconds
		#
		#
		TIME=\$( grep 'PWSCF *:.*WALL' ${APP}.${NPES}.out | sed 's/.*: *//g;s/.*CPU *//g;s/ *WALL//g' )
		HOUR=\$( echo \${TIME} | grep -q h; if [ \$? -eq 0 ]; then echo \${TIME} | sed 's/h.*//g'; else echo 0; fi )
		MINUTE=\$( echo \${TIME} | grep -q m; if [ \$? -eq 0 ]; then echo \${TIME} | sed 's/.*h//g;s/\(.*\)m.*/\1/g'; else echo 0; fi )
		SECOND=\$( echo \${TIME} | sed 's/.*m//g;s/\(.*\)s/\1/g' )
		if [ "x\${HOUR}" = "x" ]; then HOUR=0; fi
		if [ "x\${MINUTE}" = "x" ]; then MINUTE=0; fi
		if [ "x\${SECOND}" = "x" ]; then SECOND=0; fi
		WALL=\$( echo "\${HOUR} * 3600 + \${MINUTE} * 60 + \${SECOND}" | bc )
		echo "PWSCF wall clock time: \${WALL}"

	EOF
}

function extra_setup ()
{
    #
    # Build application options
    #
    EXE_ARGS="${EXE_ARGS} -i ${INP}.in"

    if [ ${ARCH} = "amd" ]; then
        if [ ${HAVE_AVX512} -eq 0 ]; then
			cat >> .slurmjobscript.$$ <<- EOF
				#
				# Enable AVX2 code path in Intel MKL for AMD EPYC processors
				#
				export MKL_DEBUG_CPU_TYPE=5

			EOF
        fi
    fi

    QE_NK=0
    QE_NT=0
    QE_ND=0

    case ${INP} in 
        ausurf112)
            case ${NNODES} in
                1)
                    QE_NK=2
                    QE_NT=1
                    QE_ND=64
                    ;;


                2)
                    QE_NK=1
                    QE_NT=4
                    QE_ND=64
                    ;;

                5)
                    QE_NK=2
                    QE_NT=4
                    QE_ND=144
                    ;;

                10)
                    QE_NK=2
                    QE_NT=5
                    QE_ND=144
                    ;;
            esac
            ;;

        psiwat)
            case ${NNODES} in
                1)
                    QE_NK=2
                    QE_NT=1
                    QE_ND=64
                    ;;


                2)
                    QE_NK=4
                    QE_NT=2
                    QE_ND=121
                    ;;

                5)
                    QE_NK=4
                    QE_NT=2
                    QE_ND=144
                    ;;

                10)
                    QE_NK=4
                    QE_NT=2
                    QE_ND=144
                    ;;
            esac
            ;;

        CuO)
            case ${NNODES} in
                1)
                    QE_NK=4
                    QE_NT=1
                    QE_ND=64
                    ;;


                2)
                    QE_NK=4
                    QE_NT=2
                    QE_ND=121
                    ;;

                5)
                    QE_NK=4
                    QE_NT=5
                    QE_ND=289
                    ;;

                10)
                    QE_NK=8
                    QE_NT=5
                    QE_ND=144
                    ;;
            esac
            ;;

        Ni_Ni3Al_512)
            case ${NNODES} in
                3)
                    QE_NK=3
                    QE_NT=1
                    QE_ND=169
                    ;;
                4)
                    QE_NK=1
                    QE_NT=8
                    QE_ND=512
                    ;;
                6)
                    QE_NK=3
                    QE_NT=2
                    QE_ND=361
                    ;;
                8)
                    QE_NK=3
                    QE_NT=2
                    QE_ND=1024
                    ;;
                9)
#                    QE_NK=3
#                    QE_NT=3
#                    QE_ND=576
                    QE_NK=1
                    QE_NT=1
                    QE_ND=1
                    ;;
            esac
            ;;

        *)
            QE_NK=0
            QE_NT=0
            QE_ND=0
            ;;

    esac

    #
    # Setting up QE pools, one per node for now
    #
    if [ ${QE_NK} -eq 0 ]; then
        QE_NK=${NNODES}
    fi

    #
    # Setting up QE task group for the 3D FFTs, one per socket
    #
    if [ ${QE_NT} -eq 0 ]; then
        QE_NT=$(( QE_NK / 2 ))
    fi

    #
    # Number of tasks for ScaLAPACK/ELPA diagonalization
    # Make it square
    #
    if [ ${QE_ND} -eq 0 ]; then
        FOUND=0
        QE_ND=${NPES}
        while [ ${FOUND} -ne 1 ]; do
            RES_ROOT=$( echo "scale=2; sqrt(${QE_ND})" | bc )
            echo ${RES_ROOT} | grep -q '\.00'
            INT_ROOT=$?
            if [ ${INT_ROOT} -eq 0 ]; then
                echo "$(basename $0): found ${QE_ND} cores (${RES_ROOT}x${RES_ROOT}) for ScaLAPACK/ELPA diagonalization."
                FOUND=1
                break
            fi
            QE_ND=$(( QE_ND - 1 ))
        done
    fi

    EXE_ARGS="${EXE_ARGS} -nk ${QE_NK} -nt ${QE_NT} -nd ${QE_ND}"

    #
    # For QE 6.8, we now need the '-pd true' flag for parallel FFTs
    # See https://www.mail-archive.com/users@lists.quantum-espresso.org/msg40955.html
    #
    # Otherwise:
    #  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    #     Error in routine  fft_type_init (1):
    #  Slab decomposition and task groups not implemented.
    #
    #  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    #
    #if [ ${VERSION} = 6.8 ]; then
    #     EXE_ARGS="${EXE_ARGS} -pd true"
    #fi
    
}
