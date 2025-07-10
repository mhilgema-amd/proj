#!/bin/bash

function parse_options ()
{
    #
    # Process command line arguments
    #
    ARGV=$#
    OPTIND=1
    while getopts ":a:B:b:c:e:i:m:n:p:q:s:t:w:x:X:y:z:Z:dC:DAHL:M:N:OPQ:FS:T:UVv" args; do
        case "$args" in
            A)
                LIBAPS=1
                echo "$(basename $0): Intel APS profiling is enabled."
                ;;
            a)
                VERSION=$OPTARG
                echo "$(basename $0): ${APP} version = ${VERSION}"
                ;;
            B)
                PREFIX=$OPTARG
                BUILD=$(basename ${PREFIX})
                HAVE_PREFIX=1
                echo "$(basename $0): Build directory = ${PREFIX}"
                ;;
            b)
                BUILD=$OPTARG
                SUFFIX=$OPTARG
                echo "$(basename $0): Build version = ${BUILD}"
                ;;
            C)
                SOCKET=$OPTARG
                echo "$(basename $0): Number of sockets = ${SOCKET}"
                if [ ${SOCKET} -lt 1 ] || [ ${SOCKET} -gt 2 ]; then
                    echo "$(basename $0): Invalid number of sockets: ${SOCKET}"
                    exit 1
                fi
                ;;
            c)
                TMP_COMPILER=${OPTARG}
                case ${TMP_COMPILER} in
                    aocc*|gcc*|intel*)
                        COMPILER=${TMP_COMPILER}
                        ;;
                    *)
                        echo "$(basename $0): unsupported compiler. Choose 'aocc', 'gcc' or 'intel'."
                        exit 1
                        ;;
                esac
                echo "$(basename $0): compiler = ${COMPILER}"
                ;;
            d)
                TOOLBOX=1
                echo "$(basename $0): Dell Toolbox MPI profiling is enabled."
                ;;
            D)
                LIBMPIP=1
                echo "$(basename $0): MPIP MPI profiling is enabled."
                ;;
            e)
                SLURM_OPTS=$OPTARG
                echo "$(basename $0): extra SLURM options = ${SLURM_OPTS}"
                ;;
            F)
                LIBF1COUNT=1
                echo "$(basename $0): Dell instruction counting enabled."
                ;;
            H)
                HUGE_PAGES=1
                echo "$(basename $0): Huge pages enabled."
                ;;
            i)
                INP=$OPTARG
                if [ ! -d ${INPD}/${INP} ] && [ ! -f ${INPD}/${INP} ]; then
                    echo "$(basename $0): input file does not exist"
                    exit 1
                fi
                echo "$(basename $0): input file = ${INP}"
                ;;
            L)
                L3=$OPTARG
                echo "$(basename $0): Number of cores per L3: ${L3}"
                if [ ${L3} -lt 1 ] || [ ${L3} -gt 4 ]; then
                    echo "$(basename $0): Invalid number of cores per L3: ${L3}"
                    exit 1
                fi
                ;;
            m)
                MPI=$OPTARG
                echo "$(basename $0): MPI library = ${MPI}"
                ;;
            M)
                NPS=$OPTARG
                case "${NPS}" in
                    1|2|4)
                        echo "$(basename $0): NPS: ${NPS}"
                        ;;
                    *)
                        echo "$(basename $0): Invalid NPS number: ${NPS}"
                        exit 1
                        ;;
                esac
                ;;
            n)
                PPN=$OPTARG
                echo "$(basename $0): PPN = ${PPN}"
                ;;
            N)
                NNODES=$OPTARG
                echo "$(basename $0): number of nodes = ${NNODES}"
                ;;
            p)
                PARTITION=$OPTARG
                echo "$(basename $0): SLURM Partition is ${PARTITION}"
                ;;
            O)
                LIBOPROFILE=1
                echo "$(basename $0): Oprofile profiling is enabled."
                ;;
            P)
                LIBPERF=1
                echo "$(basename $0): Linux Perf profiling is enabled."
                ;;
            Q)
                CCD=$OPTARG
                case "${CCD}" in
                    1|2|4|6|8)
                        echo "$(basename $0): number of CCDs: ${CCD}"
                        ;;
                    *)
                        echo "$(basename $0): Invalid number of CCDs: ${CCD}"
                        USAGE
                        exit 1
                        ;;
                esac
                ;;
           q)
                NTHREADS=$OPTARG
                echo "$(basename $0): number of threads = ${NTHREADS}"
                ;;
           S)
                SMT=$OPTARG
                case "${SMT}" in
                    0)
                        echo "$(basename $0): SMT is disabled."
                        ;;
                    1)
                        echo "$(basename $0): SMT is enabled."
                        ;;
                    *)
                        echo "$(basename $0): Invalid SMT option: ${SMT}"
                        USAGE
                        exit 1
                        ;;
                esac
                ;;
           s)
                SCR=$OPTARG
                if [ ! -d ${SCR} ]; then
                    mkdir -p ${SCR} > /dev/null 2>&1
                    if [ $? -ne 0 ]; then
                        echo "$(basename $0): unable to create scratch directory: ${SCR}"
                        USAGE
                        exit 1
                    fi
                fi

                touch ${SCR}/a_file  > /dev/null 2>&1
                if [ $? -ne 0 ]; then
                    echo "$(basename $0): scratch directory is not writeable: ${SCR}"
                    USAGE
                    exit 1
                fi
                rm ${SCR}/a_file

                echo "$(basename $0): scratch directory = ${SCR}"
                ;;
            T)
                BOOST=$OPTARG
                case "${BOOST}" in
                    0)
                        echo "$(basename $0): Boost is disabled."
                        ;;
                    1)
                        echo "$(basename $0): Boost is enabled."
                        ;;
                    *)
                        echo "$(basename $0): Invalid Boost option: ${BOOST}"
                        USAGE
                        exit 1
                        ;;
                esac
                ;;
            t)
                TIME=$OPTARG
                echo "$(basename $0): wall clock time = ${TIME}"
                ;;
            x)  
                case "${APP}" in
                    gamess)
                        EXTRA_OPTION1="${OPTARG}"
                        echo "$(basename $0): ${TEXT_EXTRA_OPTION1} ${EXTRA_OPTION1}"
                        VERNO=${EXTRA_OPTION1}
                        EXE=gamess.${VERNO}.x
                        ;;
                    gromacs)
                        EXTRA_OPTION1="${OPTARG}"
                        echo "$(basename $0): ${TEXT_EXTRA_OPTION1} ${EXTRA_OPTION1}"
                        GROMACS_NSTEPS=${EXTRA_OPTION1}
                        ;;
                    lammps)
                        EXTRA_OPTION1="${OPTARG}"
                        case "${EXTRA_OPTION1}" in
                            omp)
                                echo "$(basename $0): USER-OMP option selected."
                                ;;
                            opt)
                                echo "$(basename $0): USER-OPT option selected."
                                ;;
                            intel)
                                echo "$(basename $0): USER-INTEL option selected."
                                ;;
                            *)
                                echo "$(basename $0): Invalid LAMMPS option: ${EXTRA_OPTION1}"
                                USAGE
                                exit 1
                                ;;
                        esac
                        ;;
                    vasp)
                        EXTRA_OPTION1="${OPTARG}"
                        case "${EXTRA_OPTION1}" in
                            gam)
                                EXE=vasp_gam
                                ;;
                            std)
                                EXE=vasp_std
                                ;;
                            ncl)
                                EXE=vasp_ncl
                                ;;
                            *)
                                echo "$(basename $0): Invalid VASP executable: ${EXTRA_OPTION1}"
                                echo "$0 -x <gam|std|ncl>"
                                exit 1
                                ;;
                        esac
                        find_executable
                        echo "$(basename $0): VASP executable: ${EXE}"
                        ;;
                    wrf)
                        EXTRA_OPTION1="${OPTARG}"
                        TEXT_EXTRA_OPTION1="WRF nproc_x value"
                        echo "$(basename $0): WRF nproc_x value: ${EXTRA_OPTION1}"
                        ;;
                    *)
                        echo "$(basename $0): Invalid option for application ${APP}"
                        USAGE
                        exit 1
                        ;;
                esac
                ;;
            X)  
                case "${APP}" in
                    vasp)
                        EXTRA_OPTION2="${OPTARG}"
                        echo "$(basename $0): VASP KPAR value: ${EXTRA_OPTION2}"
                        ;;
                    wrf)
                        EXTRA_OPTION2="${OPTARG}"
                        echo "$(basename $0): WRF nproc_y value: ${EXTRA_OPTION2}"
                        ;;
                    *)
                        echo "$(basename $0): Invalid option for application ${APP}"
                        USAGE
                        exit 1
                        ;;
                esac
                ;;
            U)
                LIBUPROF=1
                echo "$(basename $0): AMD uPROF profiling is enabled."
                ;;
            V)
                LIBVTUNE1=1
                echo "$(basename $0): Intel VTune HPC performance profiling is enabled."
                ;;
            v)
                LIBVTUNE2=1
                echo "$(basename $0): Intel VTune hotspot profiling is enabled."
                ;;
            w)
                NODENAME=$OPTARG
                echo "$(basename $0): node hostname = ${NODENAME}"
                ;;
            y)
                MPI_OPTION=$OPTARG
                echo "$(basename $0): MPI_OPTION = ${MPI_OPTION}"
                ;;
            z)
                MPI_OPTION_VAL=$OPTARG
                echo "$(basename $0): MPI_OPTION_VAL = ${MPI_OPTION_VAL}"
                ;;
            \?)
                echo "$(basename $0): invalid option: -$OPTARG" >&2
                USAGE
                ;;
            Z)  
                case "${APP}" in
                    wrf)
                        EXTRA_OPTION3="${OPTARG}"
                        echo "$(basename $0): WRF I/O quilt servers: ${EXTRA_OPTION3}"
                        ;;
                    *)
                        echo "$(basename $0): Invalid option for application ${APP}"
                        USAGE
                        exit 1
                        ;;
                esac
                ;;
        esac
    done
    shift $((OPTIND-1))
}

function verify_options ()
{
    #if [ ${HAVE_PREFIX} -eq 1 ]; then
        find_executable
    #fi

    if [ x${INP} = x -o x${NNODES} = x  ]; then
        USAGE
    fi

    if [ x${INP} = x ]; then
        if [ ! -d ${INPD}/${INP} ] && ! -f ${INPD}/${INP} ]; then
            echo "Directory or file ${INPD}/${INP} does not exist!"
            exit 1
        fi
    fi

    if [ x${PPN} = x ]; then
        PPN=$(( NODE_SIZE[${PARTITION}] / NTHREADS ))
    fi
    NPES=$(( NNODES * PPN ))
    NCORES=$(( PPN * NTHREADS ))

    #
    # Convert an associative element to a number, otherwise the if statment fails
    #
    if [ ${NCORES} -gt ${NODE_SIZE[${PARTITION}]} ]; then
        echo "$(basename $0): Specified number of cores (${NCORES}) is larger than node size (${NODE_SIZE[${PARTITION}]})"
        echo "Exiting."
        exit 1
    fi

    if [ x${MPI} = xopenmpi ]; then
        MPIVER=4.1.4
    elif [ x${MPI} = ximpi ]; then
        MPIVER="2019u12"
    fi

    #
    # We don't know whether different build was asked, so set $PREFIX again just to be sure.
    #
    if [ x${BUILD} = x ]; then
        BUILD="${COMPILER}"
    fi
	#PREFIX=${HOME}/app/${APP}/work/${VERSION}/${BUILD}
}

function find_executable ()
{
#
# If the first letter of ${PREFIX} does *not* begin with a '/'; then assume that it 
# is a module path
#
    if [ ${HAVE_PREFIX} -eq 1 ]; then
        if [ $( echo ${PREFIX} | sed 's/\(^.\).*/\1/' ) != "/" ]; then
            APP_MOD=${PREFIX}
            module is-avail ${APP_MOD}
            if [ $? -eq 0 ]; then
                HAVE_MOD=1
            else
                echo "$( basename $0 ): find_executable: module ${APP_MOD} does not exist"
                exit 1
            fi
        else
            if [ -d ${PREFIX} ]; then
                HAVE_PREFIX=1
            else
                echo "$( basename $0 ): installation path ${PREFIX} does not exist"
                exit 1
            fi
        fi
    fi


#
# Last resort:
#
# Check for an available module in a default installation path
#
    if [ ${HAVE_MOD} -ne 1 -a ${HAVE_PREFIX} -ne 1 ]; then
        APP_MOD=${APP}/${COMPILER}/${MPI}/${VERSION}${SUFFIX}
        module is-avail ${APP_MOD}
        if [ $? -eq 0 ]; then
            HAVE_MOD=1
        else
            echo "$( basename $0 ): find_executable: module ${APP_MOD} does not exist"
            exit 1
        fi
    fi

#
# Find the exectable name
#
    case "${APP}" in
        cp2k)
            EXE=cp2k.psmp
            ;;
        dl_poly)
            EXE=DLPOLY.Z
            ;;
        gamess)
            EXE=gamess.${VERNO}.x
            ;;
        gromacs)
            EXE=gmx_mpi
            ;;
        lammps)
            EXE=lmp
            ;;
        openfoam)
            EXE=simpleFoam
            ;;
        qe)
            EXE=pw.x
            ;;
        vasp)
            EXE=${EXE}
            ;;
        wrf)
            EXE=wrf.exe
            ;;
        *)
           
            echo "$0: find_executable: unknown application ${APP}"
            exit 1
            ;;
    esac

    if [ ${HAVE_PREFIX} -eq 1 -a ${HAVE_MOD} -ne 1 ]; then
        EXE=$( find ${PREFIX} -executable -name ${EXE} | head -1 )
    fi

    echo "$(basename $0): Executable = ${EXE}"
}
