#!/bin/bash
#

APP=$1; shift
PREFIX="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${PREFIX}/inc/init.inc
source ${PREFIX}/inc/${APP}.inc
source ${PREFIX}/inc/options.inc
source ${PREFIX}/inc/compiler.inc
source ${PREFIX}/inc/mpi.inc
source ${PREFIX}/inc/affinity.inc
source ${PREFIX}/inc/prof.inc
source ${PREFIX}/inc/slurm.inc
source ${PREFIX}/inc/run.inc

function USAGE ()
{
	cat <<- EOF

	Usage: $0 <dl_poly|gromacs|gamess|lammps|openfoam|qe|vasp|wrf>
	
        Common options:
            -a <${APP} version>                       [ ${VERSION} ]
            -b <build version>                        [ ${BUILD} ]
            -B <${APP} build directory>               [ ${PREFIX} ]
            -c <aocc|gcc|intel>                       [ ${COMPILER} ]
            -H: Enable Huge Pages                     [ ${HUGE_PAGES} ]     
            -i <input file>                           [ ${INP} ]
            -s <scratch directory>                    [ ${SCR} ]
            -x ${TEXT_EXTRA_OPTION1}                  [ ${EXTRA_OPTION1} ]
            -X ${TEXT_EXTRA_OPTION2}                  [ ${EXTRA_OPTION2} ]
            -Z ${TEXT_EXTRA_OPTION3}                  [ ${EXTRA_OPTION3} ]

        SLURM options:
            -e <extra SLURM sbatch option>            [ ${SLURM_OPTS} ]
            -n <ppn>                                  [ ${PPN} ]
            -N <number of nodes>                      [ ${NNODES} ]
            -p <SLURM partition name>                 [ ${PARTITION} ]
            -q <threads>                              [ ${NTHREADS} ]
            -t <wall clock time>                      [ ${TIME} ]
            -w <node name(s)>

        MPI options:
            -m <MPI library>                          [ ${MPI} ]
            -y <MPI option>                           [ ${MPI_OPTION} ]
            -z <MPI option argument>                  [ ${MPI_OPTION_VAL} ]
		
        AMD parameters:
            -T <num>: Enable Boost {0,1}              [ ${BOOST} ]
            -C <num>: Number of CPU sockets {1,2}     [ ${SOCKET} ]
            -L <num>: Number of cores per L3 {1-4}    [ ${L3} ]
            -M <num>: NPS mode {1,2,4}                [ ${NPS} ]
            -S <num>: Turn SMT on {0,1}               [ ${SMT} ]
            -Q <num>: <number of CCDs {2,4,6,8}       [ ${CCD} ]
		
        Profiling options:
            -A: Intel APS profiling                   [ ${LIBAPS} ]
            -d: Martin's Toolbox profiling            [ ${TOOLBOX} ]
            -D: mpiP profiling                        [ ${LIBMPIP} ]
            -F: F1_count instruction counting         [ ${LIBF1COUNT} ]
            -O: Oprofile profiling                    [ ${LIBOPROFILE} ]
            -P: Linux Perf profiling                  [ ${LIBPERF} ]
            -U: AMD uPROF profiling                   [ ${LIBUPROF} ]
            -V: Intel VTune hpc-performance profiling [ ${LIBVTUNE1} ]
            -v: Intel VTune hotspot profiling         [ ${LIBVTUNE2} ]

EOF

    exit 1
}

function init ()
{
    #
    # Initialization
    #
    init_base
    init_cpu
    init_slurm
    init_prof
    init_application
}

function main ()
{
    #
    # Parse the options, setup SLURM node size, do some sanity checking
    #
    parse_options $*
    prepare_slurm
    verify_options

    #
    # Setup MPI, Compiler,Profiling and Affinity
    #
    setup_affinity
    setup_compiler
    setup_prof
    setup_mpi

    #
    # Generate the SLURM script
    #
    setup_slurm
    setup_scratch
    extra_setup
    run_sysinfo
    run_prof
    run_app

    #
    # Post processing in the job script
    #
    post_application
    post_prof

    #
    # Submit job to SLURM partition
    #
    submit_job
}

init
if [ $# -eq 0 ]; then
    USAGE
fi
main $*
