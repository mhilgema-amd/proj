#!/bin/bash
#

#
# Aliases and functions
#
shopt -s expand_aliases
alias mytime='/usr/bin/time -f "Elapsed: %e  User: %U  System: %S  PageF: %F"'

#
# Default parameters
#
function init_base ()
{
    BUILD=
    NSOCK=2
    PREFIX=${HOME}/app/${APP}/work/${VERSION}/${BUILD}
    INPD=${HOME}/app/${APP}/inp
    SCR=${HOME}/scratch/${APP}
    HAVE_PREFIX=0
}


function init_cpu ()
{
    #
    # Default options
    #
    BOOST=0         # Boost off (0) or on (1)
    SMT=0           # SMT off (0) or on (1)
    L3=4            # Number of cores per L3 (1, 2, 3 or 4)
    NPS=4           # NPS mode (1, 2 or 4)
    SOCKET=2        # Number of sockets (1 or 2)
    CCD=8           # Number of CCDs (1, 2, 4, 6 or 8)
    HUGE_PAGES=0    # Huge pages disabled

    HAVE_AMD=$( grep 'model name' /proc/cpuinfo | grep -c AMD )
    HAVE_INTEL=$( grep 'model name' /proc/cpuinfo | grep -c Intel )
    HAVE_SMT=$( cat /sys/devices/system/cpu/smt/active )
}


function init_slurm ()
{
    NNODES=1
    NPES=1
    NTHREADS=1
    PPN=

    HAVE_MOD=0
    HAVE_PREFIX=0

    HAVE_ZENITH=0
    HAVE_MINERVA=0
    HAVE_RATTLER=0
    HAVE_BDC=0

    if [[ $( hostname ) =~ zlogin ]]; then HAVE_ZENITH=1; fi
    if [[ $( hostname ) =~ mlogin ]]; then HAVE_MINERVA=1; fi
    if [[ $( hostname ) =~ rlogin ]]; then HAVE_RATTLER=1; fi
    if [[ $( hostname ) =~ everest ]]; then HAVE_BDC=1; fi

    if [ ${HAVE_ZENITH} -gt 0 ]; then PARTITION=6248; fi
    if [ ${HAVE_MINERVA} -gt 0 ]; then PARTITION=7702; fi
    if [ ${HAVE_RATTLER} -gt 0 ]; then PARTITION=gpuq; fi
    if [ ${HAVE_BDC} -gt 0 ]; then PARTITION=7713; fi

    TIME="2:30:00"
}
