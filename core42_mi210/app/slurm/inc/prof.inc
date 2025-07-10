#!/bin/bash

function init_prof()
{
    #
    # All profiling is disabled by default
    #
    TOOLBOX=0
    LIBMPIP=0
    LIBAPS=0
    LIBPERF=0
    LIBF1COUNT=0
    LIBUPROF=0
    LIBOPROFILE=0
    LIBVTUNE1=0
    LIBVTUNE2=0
}


function setup_prof ()
{
    #
    # Setup MPI profiling if enabled
    #
    #
    if [ ${TOOLBOX} -eq 1 ]; then
        export LIBTOOLBOX="-s"
        #
        # Profiling library needs dynamically linked executable to intercept MPI calls
        #
        if [ x${LD_PRELOAD} != x ]; then
            LIBTOOLBOX_PRELOAD=${HOME}/lib/libtoolbox-${MPI}.so:${LD_PRELOAD}
        else
            LIBTOOLBOX_PRELOAD=${HOME}/lib/libtoolbox-${MPI}.so
        fi
        if [ x${MPI} = ximpi ]; then
            MPI_ARGS="${MPI_ARGS} -genv LD_PRELOAD ${LIBTOOLBOX_PRELOAD} -genv LIBTOOLBOX ${LIBTOOLBOX}"
			#MPI_ARGS="${MPI_ARGS} -genv LIBTOOLBOX_COLL_STATS 1 -genv LIBTOOLBOX_COLL_COMBINED_STATS 1"
        elif [ x${MPI} = xopenmpi ]; then
            MPI_ARGS="${MPI_ARGS} -x LD_PRELOAD=${LIBTOOLBOX_PRELOAD} -x LIBTOOLBOX=${LIBTOOLBOX}"
			#MPI_ARGS="${MPI_ARGS} -x LIBTOOLBOX_COLL_STATS=1 -x LIBTOOLBOX_COLL_COMBINED_STATS=1"
        fi
    fi

    #
    # Setup MPIP MPI profiling if enabled
    #
    #
    if [ ${LIBMPIP} -eq 1 ]; then
        export MPIP="-k3"
        #
        # Profiling library needs dynamically linked executable to 
        # intercept MPI calls
        #
        if [ x${LD_PRELOAD} != x ]; then
            MPIP_PRELOAD=/home/modules/hpc/mpip/${COMPILER}/${MPI}/3.4.1/lib/libmpiP.so:/home/modules/hpc/libunwind/1.3.1/lib/libunwind.so.8:${LD_PRELOAD}
        else
            MPIP_PRELOAD=/home/modules/hpc/mpip/${COMPILER}/${MPI}/3.4.1/lib/libmpiP.so:/home/modules/hpc/libunwind/1.3.1/lib/libunwind.so.8
        fi
        if [ x${MPI} = ximpi ]; then
            MPI_ARGS="${MPI_ARGS} -genv LD_PRELOAD ${MPIP_PRELOAD} -genv MPIP ${MPIP}"
        elif [ x${MPI} = xopenmpi ]; then
            MPI_ARGS="${MPI_ARGS} -x LD_PRELOAD=${MPIP_PRELOAD} -x MPIP=${MPIP}"
        fi
    fi

    #
    # Setup Intel APS profiling if enabled
    #
    #
    APS=""
    if [ ${LIBAPS} -eq 1 ]; then
        #
        # Need to initialize the VTUNE library
        # 
        #
        INTEL_ROOT=/cm/shared/apps/core/apps/intel
        VTUNE_ROOT=${INTEL_ROOT}/vtune_amplifier
        APS_ROOT=${INTEL_ROOT}/performance_snapshots
        APS="vtune -collect performance-snapshot -r \${SCR}/aps -- "
        if [ "x${MPI}" = "ximpi" ]; then
            MPI_ARGS="${MPI_ARGS} -genv MPS_STAT_LEVEL 4"
        else
            MPI_ARGS="${MPI_ARGS} -x MPS_STAT_LEVEL=4"
        fi
    fi

    #
    # Setup Linux Perf profiling if enabled
    #
    #
    PERF=""
    if [ ${LIBPERF} -eq 1 ]; then
        #
        # Special treatment for GAMESS US run script
        #
        #
        if [ "x${APP}" = "xgamess" ]; then
            MPIRUN="${PREFIX}/gamess/rungms.perf"
        else
            PERF=${HOME}/bin/my_perf.sh
        fi
    fi

    #
    # Setup F1 instruction counting if enabled
    #
    #
    F1COUNT=""
    if [ ${LIBF1COUNT} -eq 1 ]; then
        F1_COUNT="f1_count.exe -t -D -s -n -m -f -P -W 60 -l -i 20 -o \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_NAME}.\${SLURM_JOB_ID}.csv"
        #
        # Do power consumption on Intel
        #
        if [ "x${ARCH}" = x"intel" ]; then
            F1_COUNT="${F1_COUNT} -p"
        fi
    fi

    #
    # Setup AMD uPROF profiling if enabled
    #
    #
    UPROF=""
    if [ ${LIBUPROF} -eq 1 ]; then
        UPROF="${HOME}/bin/my_uprof.sh"
    fi

    #
    # Setup Oprofile profiling if enabled
    #
    #
    OPROFILE=""
    if [ ${LIBOPROFILE} -eq 1 ]; then
        #
        # Special treatment for GAMESS US run script
        #
        #
        if [ "x${APP}" = "xgamess" ]; then
            MPIRUN="${PREFIX}/gamess/rungms.oprofile"
        else
            OPROFILE="${HOME}/bin/my_oprofile.sh"
        fi
    fi

    #
    # Setup Intel VTune profiling if enabled
    #
    #
    VTUNE=""
    if [ ${LIBVTUNE1} -eq 1 ] || [ ${LIBVTUNE2} -eq 1 ]; then
        #
        # Need to initialize the VTUNE library.
        # We only profile MPI ranks 0 and 1
        # 
        #
        INTEL_ROOT=/cm/shared/apps/core/apps/intel
        VTUNE_ROOT=${INTEL_ROOT}/vtune_amplifier
        if [ "x${MPI}" = "ximpi" ]; then
            if [ ${LIBVTUNE1} -eq 1 ]; then
                VTUNE1="amplxe-cl –collect hpc-performance –r \${SCR}/vtune.out -- "
            else
                VTUNE2="-gtool $(echo '\"') amplxe-cl –collect hotspots –r \${SCR}/vtune.out :0-1 $(echo '\"')"
            fi
        else
            echo "$0: init_prof: VTune profiling is only supported with Intel MPI."
            exit 1
        fi
    fi

    #
    # Setup Huge Pages with TBB
    #
    #
    if [ ${HUGE_PAGES} -eq 1 ]; then
        #
        # Inserting the TBB memory allocator though LD_PRELOAD
        #
        if [ x${LD_PRELOAD} != x ]; then
            HUGE_PRELOAD=libtbbmalloc_proxy.so:libtbbmalloc.so:libtbb.so:${LD_PRELOAD}
        else
            HUGE_PRELOAD=libtbbmalloc_proxy.so:libtbbmalloc.so:libtbb.so
        fi
        if [ x${MPI} = ximpi ]; then
            MPI_ARGS="${MPI_ARGS} -genv LD_PRELOAD ${HUGE_PRELOAD} -genv TBB_MALLOC_USE_HUGE_PAGES 1"
        elif [ x${MPI} = xopenmpi ]; then
            MPI_ARGS="${MPI_ARGS} -x LD_PRELOAD=${HUGE_PRELOAD} -x TBB_MALLOC_USE_HUGE_PAGES=1"
        fi
    fi

}

function run_prof ()
{
    if [ ${LIBAPS} -eq 1 ]; then
		cat >> .slurmjobscript.$$ <<- EOF
		#
		# Need to initialize the VTUNE library
		# 
		#
			source ${VTUNE_ROOT}/amplxe-vars.sh
			source ${APS_ROOT}/apsvars.sh

		EOF
    fi

    if [ ${LIBVTUNE1} -eq 1 ] || [ ${LIBVTUNE2} -eq 1 ]; then
		cat >> .slurmjobscript.$$ <<- EOF
		#
		# Need to initialize the VTUNE library
		# 
		#
			source ${VTUNE_ROOT}/amplxe-vars.sh

		EOF
    fi

    if [ ${LIBF1COUNT} -eq 1 ]; then
		cat >> .slurmjobscript.$$ <<- EOF
		#
		# Start the F1_count collector
		# 
		#
			${F1_COUNT} &
			F1_COUNT_PID=\$!

		EOF
    fi
}

function post_prof ()
{

	if [ ${TOOLBOX} -eq 1 ]; then
	cat >> .slurmjobscript.$$ <<- EOF
		#
		# Libtoolbox post processing
		#
		if [ ! -d \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID} ]; then 
			mkdir -p \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}
		fi
		cp libtoolbox_*.\${SLURM_JOB_ID}.csv \${SLURM_SUBMIT_DIR}
	EOF
	fi

	if [ ${LIBMPIP} -eq 1 ]; then
	cat >> .slurmjobscript.$$ <<- EOF
		#
		# mpiP post processing
		#
		if [ ! -d \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID} ]; then 
			mkdir -p \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}
		fi
		cat *.mpiP
		cp *.mpiP \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}
	EOF
	fi

	if [ ${LIBAPS} -eq 1 ]; then
	cat >> .slurmjobscript.$$ <<- EOF
		#
		# Aps post processing
		#
		if [ ! -d \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID} ]; then 
		    mkdir -p \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}
		fi
		for NNODE in \$( scontrol show hostnames ); do
		    vtune -report summary -r \${SCR}/aps.\${NNODE} -format=html -report-output=\${SCR}/aps.out.\${SLURM_JOB_ID}.\${NNODE}.html
		    if [ ! -f \${SCR}/aps.out.\${SLURM_JOB_ID}.\${NNODE}.html ]; then
		        cp \${SCR}/aps.out.\${SLURM_JOB_ID}.\${NNODE}.html \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}
		    fi
		done
	EOF
	fi

	if [ ${LIBPERF} -eq 1 ]; then
	cat >> .slurmjobscript.$$ <<- EOF
		#
		# Perf post processing
		#
		if [ ! -d \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID} ]; then 
			mkdir -p \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}
		fi
		perf report --stdio -i \${SCR}/perf.data.rank_0
		cp perf.data* \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}
	EOF
	fi

	if [ ${LIBUPROF} -eq 1 ]; then
	cat >> .slurmjobscript.$$ <<- EOF
		#
		# Uprof post processing
		#
		if [ ! -d \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID} ]; then 
			mkdir -p \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}
		fi
		echo "AMD uPROF collecting not yet implemented"
	EOF
	fi

	if [ ${LIBOPROFILE} -eq 1 ]; then
	cat >> .slurmjobscript.$$ <<- EOF
		#
		# Oprofile post processing
		#
		if [ ! -d \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID} ]; then 
		    mkdir -p \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}
		fi
		which opreport > /dev/null 2>&1
		if [ \$? -ne 0 ]; then
		     module load oprofile
		fi
		opreport --accumulated --session-dir=\${SCR}/oprofile.0 --debug-info --symbols
		echo -ne "\nDetailed profile information can be obtained with:\n\topreport --accumulated --symbols --session-dir=\${SCR}/oprofile.0 --debug-info --details|less\n"
		rsync -a \${SCR}/oprofile* \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}
	EOF
	fi

	if [ ${LIBVTUNE1} -eq 1 ] || [ ${LIBVTUNE2} -eq 1 ]; then
	cat >> .slurmjobscript.$$ <<- EOF
		#
		# VTune post processing
		#
		if [ ! -d \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID} ]; then 
		    mkdir -p \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}
		fi

	EOF
		if [ ${LIBVTUNE1} -eq 1 ]; then
	cat >> .slurmjobscript.$$ <<- EOF
		    for NNODE in \$(scontrol show hostnames); do
		        amplxe-cl -report hotspots -r \${SCR}/vtune.out.\${NNODE} -format=html -report-output=\${SCR}/vtune.out.\${SLURM_JOB_ID}.\${NNODE}.html
		        if [ ! -f \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}/vtune.out.\${SLURM_JOB_ID}.csv ]; then
		            cp \${SCR}/vtune.out.\${SLURM_JOB_ID}.*.html \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}
		        fi
		    done
	EOF
		else
	cat >> .slurmjobscript.$$ <<- EOF
		    amplxe-cl -report hotspots -r \${SCR}/vtune.out.\$(hostname) -format=text -report-output=\${SCR}/vtune.out.\${SLURM_JOB_ID}.txt
		    if [ ! -f \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}/vtune.out.\${SLURM_JOB_ID}.txt ]; then
		        cp \${SCR}/vtune.out.\${SLURM_JOB_ID}.txt \${SLURM_SUBMIT_DIR}/\${SLURM_JOB_ID}
		    fi
	EOF
		fi
	fi

    if [ ${LIBF1COUNT} -eq 1 ]; then
		cat >> .slurmjobscript.$$ <<- EOF
		#
		# Stop the F1_count collector
		# 
		#
			kill -s INT \${F1_COUNT_PID}

		EOF
    fi
}
