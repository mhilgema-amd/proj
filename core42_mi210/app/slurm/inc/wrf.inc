#!/bin/bash
#

function init_application ()
{
    APP=wrf
    VERSION=3.9.1.1
    BUILD=
    NSOCK=2
    MPI=openmpi
    COMPILER=intel20
    PREFIX=${HOME}/app/${APP}/work/${VERSION}/${BUILD}
    INPD=${HOME}/app/${APP}/inp
    INP=
    EXE=wrf.exe
    EXE_ARGS=""
    EXTRA_OPTION=""
    TEXT_EXTRA_OPTION1="<WRF nproc_x value>  "
    TEXT_EXTRA_OPTION2="<WRF nproc_y value>  "
    TEXT_EXTRA_OPTION3="<WRF I/O quilt servers>"
}

function post_application ()
{
    #
    # Calculate forecast hours per hour for CHPC bench_2.5km case
    #
    if [[ ${INP} =~ bench_2.5km* ]]; then
		cat >> .slurmjobscript.$$ <<- EOF
			${HOME}/app/wrf/bin/simspeed_chpc.sh \${SCR}/rsl.out.0000
	
		EOF
    else
		cat >> .slurmjobscript.$$ <<- EOF
			${HOME}/app/wrf/bin/simspeed.sh \${SCR}/rsl.out.0000
	
		EOF
    fi
}

function extra_setup ()
{
    if [ ${HAVE_MOD} -eq 0 ]; then
		cat >> .slurmjobscript.$$ <<- EOF
			#
			# Load WRF modules
			#
			module load hdf5/${COMPILER}/${MPI}/1.10.7
			module load netcdf/${COMPILER}/${MPI}/4.7.4
			module load pnetcdf/${COMPILER}/${MPI}/1.12.1
			module load szip/${COMPILER}/2.1.1
			module load jemalloc/5.2.1
		
		EOF
    fi
    if [ "x${EXTRA_OPTION1}" != "x" ] && [ "x${EXTRA_OPTION2}" != "x" ]; then
		cat >> .slurmjobscript.$$ <<- EOF
			#
			# Modify the namelist for NPROC_X and NPROC_Y
			#
			grep -q nproc_x namelist.input
			if [ \$? -eq 0 ]; then
			    sed -i "s/nproc_x.*/ nproc_x = ${EXTRA_OPTION1},/g" namelist.input
			    sed -i "s/nproc_y.*/ nproc_y = ${EXTRA_OPTION2},/g" namelist.input
			else
			    sed -i "/&domains/a nproc_y = ${EXTRA_OPTION2}," namelist.input
			    sed -i "/&domains/a nproc_x = ${EXTRA_OPTION1}," namelist.input
			fi

		EOF
    fi
    if [ "x${EXTRA_OPTION3}" != "x" ]; then
		cat >> .slurmjobscript.$$ <<- EOF
			#
			# Modify the number of I/O quilt servers in namelist.input
			#
			sed -i "s/nio_tasks_per_group.*/nio_tasks_per_group      = ${EXTRA_OPTION3},/g" namelist.input

		EOF
    fi

	cat >> .slurmjobscript.$$ <<- EOF
		#
		# Get BeeGFS stripe size and number of OSTs for the ${SCR} directory
		#
		touch \${SCR}/a_file
		MOUNT=\$( df -h \${SCR}/a_file | tail -1 | awk '{print \$NF}' )
		OSTS=\$( beegfs-ctl --mount=\${MOUNT} --getentryinfo \${SCR}/a_file | awk '/actual:/{print \$NF }' )
		STRIPE=\$( beegfs-ctl --mount=\${MOUNT} --getentryinfo \${SCR}/a_file | awk '/Chunksize:/{print \$NF}' )
		if [[ \${STRIPE} = [0-9]*K ]]; then
		    STRIPE=\${STRIPE/K/}
		    STRIPE=\$(( STRIPE * 1024 ))
		fi
		if [[ \${STRIPE} = [0-9]*M ]]; then
		    STRIPE=\${STRIPE/M/}
		    STRIPE=\$(( STRIPE * 1024 * 1024 ))
		fi
	EOF

	cat >> .slurmjobscript.$$ <<- EOF
		#
		# Configure ROMIO/MPI-IO and PnetCDF
		#
		export PNETCDF_HINTS="romio_cb_write=enable;romio_ds_write=enable;striping_unit=\${STRIPE};nc_header_read_chunk_size=\${STRIPE};nc_header_align_size=\${STRIPE};nc_var_align_size=\${STRIPE};cb_nodes=\${OSTS}"

		cat > \${SCR}/romio_hints.txt <<- EOF2
			romio_cb_write            enable
			romio_ds_write            enable
			striping_unit             \${STRIPE}
			nc_header_read_chunk_size \${STRIPE}
			nc_header_align_size      \${STRIPE}
			nc_var_align_size         \${STRIPE}
			cb_nodes                  \${OSTS}
			cb_buffer_size            \${STRIPE}
			striping_factor           \${OSTS}
		EOF2

	EOF

	if [ ${MPI} = "impi" ]; then
		MPI_ARGS="${MPI_ARGS} -genv I_MPI_EXTRA_FILESYSTEM 0 -genv ROMIO_HINTS \${SCR}/romio_hints.txt -genv ROMIO_PRINT_HINTS 1"
        if [[ ${INP} =~ "vssc" ]]; then
            MPI_ARGS="${MPI_ARGS} -genv WRF_NUM_TILES 24"
        fi
	fi

	if [ ${MPI} = "openmpi" ]; then
		MPI_ARGS="${MPI_ARGS} --mca io romio321 -x ROMIO_HINTS=\${SCR}/romio_hints.txt -x ROMIO_PRINT_HINTS=1"
        if [[ ${INP} =~ "vssc" ]]; then
            MPI_ARGS="${MPI_ARGS} -x WRF_NUM_TILES=24"
        fi
	fi
}
