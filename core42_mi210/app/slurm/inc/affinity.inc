#!/bin/bash

function setup_affinity ()
{
    #
    # Set the affinity
    #
    #
    AFFINITY="${HOME}/bin/my_affinity.exe -v -n ${PPN} -t ${NTHREADS}"

    if [ ${HAVE_AMD} -gt 0 ]; then
        AFFINITY="${AFFINITY}"
    fi

    if [ ${HAVE_INTEL} -gt 0 ]; then
        AFFINITY="${AFFINITY}"
    fi
}
