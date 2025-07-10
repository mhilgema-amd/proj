#!/bin/bash

declare -A NODE_SIZE

function prepare_slurm ()
{
    #
    # Setup the node sizes for each SLURM partition
    #

    #
    # Minerva
    #
    NODE_SIZE[7282]=32
    NODE_SIZE[7302]=32
    NODE_SIZE[7343]=32
    NODE_SIZE[7373X]=32
    NODE_SIZE[7F52]=32
    NODE_SIZE[7402]=48
    NODE_SIZE[7413]=48
    NODE_SIZE[7443]=48
    NODE_SIZE[7452]=64
    NODE_SIZE[7452HT]=128
    NODE_SIZE[7502]=64
    NODE_SIZE[7513]=64
    NODE_SIZE[7543]=64
    NODE_SIZE[7532]=64
    NODE_SIZE[7573X]=64
    NODE_SIZE[7643]=96
    NODE_SIZE[7702]=128
    NODE_SIZE[7713]=128
    NODE_SIZE[7713SMT]=256
    NODE_SIZE[7763]=128
    NODE_SIZE[7773X]=128
    NODE_SIZE[7F52]=32
    NODE_SIZE[7H12]=128
    NODE_SIZE[9354]=64
    NODE_SIZE[9354-gen4]=64
    NODE_SIZE[9354-gen5]=64

    #
    # Zenith
    #
    NODE_SIZE[6248]=40
    NODE_SIZE[6230]=48
    NODE_SIZE[6252]=48
    NODE_SIZE[8260]=48
    NODE_SIZE[8280]=56
    NODE_SIZE[8352Y]=64
    NODE_SIZE[8358]=64
    NODE_SIZE[8480]=112

    #
    # BDC
    #
    NODE_SIZE[A100]=128
    NODE_SIZE[AMD7542]=64
    NODE_SIZE[AMD7543]=64
    NODE_SIZE[AMD7662]=96
    NODE_SIZE[AMD7713]=128
    NODE_SIZE[AMD7713T]=256
    NODE_SIZE[AMD7742]=128
    NODE_SIZE[AMD7763]=128
    NODE_SIZE[AMD7H12]=128
    NODE_SIZE[INTEL6248R]=48
    NODE_SIZE[INTEL8268]=48
    NODE_SIZE[INTEL8358P]=64
    NODE_SIZE[INTEL8368]=76
    NODE_SIZE[INTEL8380]=80
    NODE_SIZE[MI100]=128

#
# Rattler
#
    NODE_SIZE[gpuq]=40
    NODE_SIZE[xe8545]=128
}

function setup_slurm ()
{
    case "${PARTITION}" in
        AMD7542|AMD7543|AMD7662|AMD7713|AMD7713T|AMD7742|AMD7763|AMD7F72|AMD7H12)
            CONFIG="${PARTITION}.${NNODES}n.${NCORES}c.${PPN}ppn.${NTHREADS}t.smt${SMT}.ccd${CCD}.nps${NPS}.${SOCKET}s.${L3}l3.boost${BOOST}"
            ARCH=amd
            ;;
        7302|7402|7413|7443|7502|7513|7542|7543|7662|7702|7713SMT|7713|7763|7F52|7H12|9354*)
            CONFIG="${PARTITION}.${NNODES}n.${NCORES}c.${PPN}ppn.${NTHREADS}t.smt${SMT}.ccd${CCD}.nps${NPS}.${SOCKET}s.${L3}l3.boost${BOOST}"
            ARCH=amd
            ;;
        xe8545)
            CONFIG="${PARTITION}.${NNODES}n.${NCORES}c.${PPN}ppn.${NTHREADS}t.smt${SMT}.ccd${CCD}.nps${NPS}.${SOCKET}s.${L3}l3.boost${BOOST}"
            ARCH=amd
            ;;
        6230|6248|6252|8260|8280|8352Y|8358|8480)
            CONFIG="${PARTITION}.${NNODES}n.${NCORES}c.${PPN}ppn.${NTHREADS}t.smt${SMT}.${SOCKET}s.boost${BOOST}"
            ARCH=intel
            ;;
        INTEL6150|INTEL6242R|INTEL6248|INTEL6248R|INTEL8268|INTEL8358P|INTEL8368|INTEL8380)
            CONFIG="${PARTITION}.${NNODES}n.${NCORES}c.${PPN}ppn.${NTHREADS}t.smt${SMT}.${SOCKET}s.boost${BOOST}"
            ARCH=intel
            ;;
        gpuq)
            CONFIG="${PARTITION}.${NNODES}n.${NCORES}c.${PPN}ppn.${NTHREADS}t.smt${SMT}.${SOCKET}s.boost${BOOST}"
            ARCH=intel
            ;;
        *)
            CONFIG="${PARTITION}.${NNODES}n.${NCORES}c.${PPN}ppn.${NTHREADS}t.smt${SMT}.${SOCKET}s.boost${BOOST}"
            ARCH=intel
            ;;
    esac

    #
    # When a module is used, the version string ends up twice in the job string
    #
    if [ ${HAVE_MOD} -eq 1 ]; then
		cat >> .slurmjobscript.$$ <<- EOF
			#!/bin/bash
			#SBATCH -J ${APP}.${VERSION}.${INP}.${CONFIG}
			#SBATCH -o ${APP}.${VERSION}.${INP}.${CONFIG}.%N.o%j
		EOF
    else
		cat >> .slurmjobscript.$$ <<- EOF
			#!/bin/bash
			#SBATCH -J ${APP}.${VERSION}.${BUILD}.${INP}.${CONFIG}
			#SBATCH -o ${APP}.${VERSION}.${BUILD}.${INP}.${CONFIG}.%N.o%j
		EOF
    fi

	cat >> .slurmjobscript.$$ <<- EOF
		#SBATCH -N ${NNODES}
		#SBATCH -n ${NPES}
		#SBATCH -c ${NTHREADS}
		#SBATCH -t ${TIME}
		###SBATCH -w ${NODENAME}
		#SBATCH -p ${PARTITION}
		#SBATCH --mail-user=martin_hilgeman@dell.com
		#SBATCH --mail-type=begin  # email me when the job starts
		#SBATCH --mail-type=end    # email me when the job finishes
		##SBATCH --reservation=nps${NPS}smt${SMT}
	
		shopt -s expand_aliases
		alias mytime='/usr/bin/time -f "Elapsed: %e  User: %U  System: %S  PageF: %F"'
	
		#
		# Load modules
		#
		#
		. /etc/profile.d/modules.sh
	EOF
	
	if [ ${HAVE_MOD} -eq 1 ]; then
		cat >> .slurmjobscript.$$ <<- EOF
			
			#
			# If there's a module available for ${APP}, load it
			#
			#
			module load ${APP_MOD}
		EOF
    else
		cat >> .slurmjobscript.$$ <<- EOF
			module load ${COMPILER_MODULE}
		EOF

	    if [ ${COMPILER} = "intel21" ]; then
	        MOD=$( echo ${COMPILER_MODULE} | awk -F/ '{print $NF}' )
			cat >> .slurmjobscript.$$ <<- EOF2
			    module load compiler/${MOD}
			EOF2
	    fi

		cat >> .slurmjobscript.$$ <<- EOF3
			module load ${MPI_MODULE}
		EOF3

	fi

	if [ "x${APP}" = "xopenfoam" ]; then
	cat >> .slurmjobscript.$$ <<- EOF
		#
		# Source the OpenFOAM environment
		#
		if [ "x\${FOAM_INST_DIR}" != "x" ]; then
		    source \${FOAM_INST_DIR}/etc/bashrc
		else
		    echo "FOAM_INST_DIR not defined. Exiting."
		    exit 1
		fi

	EOF
	fi

	if [ ${HUGE_PAGES} -eq 1 ]; then
	cat >> .slurmjobscript.$$ <<- EOF
		module load tbb/${COMPILER}/2020u3

	EOF
	fi

	#
	# Fix the PATH for Open MPI with Intel compilers to avoid that Intel MPI is being loaded
	#
	if [ ${MPI} = "openmpi" ]; then
	    if [[ ${COMPILER} =~ intel* ]]; then
			cat >> .slurmjobscript.$$ <<- EOF
				COUNT=1
				for LINE in \$( echo \${PATH} | awk -F: '{ for(i=1;i<=NF;i++) if (\$i !~ /[/]mpi[/]/) {print \$i} }' ); do 
				    if [ \${COUNT} -eq 1 ]; then 
				        MY_PATH=\${LINE}
				    else
				        MY_PATH=\${MY_PATH}:\${LINE}
				    fi
				    COUNT=\$(( COUNT + 1 ))
				done
				export PATH=\${MY_PATH}

			EOF
	    fi
	fi


	cat >> .slurmjobscript.$$ <<- EOF
		export OMP_NUM_THREADS=${NTHREADS}
		PPN=$(( ${NPES}/${NNODES} ))

	EOF
	if [ ${NTHREADS} -gt 1 ]; then
		cat >> .slurmjobscript.$$ <<- EOF
			export KMP_STACKSIZE=256M

		EOF
	fi

}

function setup_scratch ()
{
	cat >> .slurmjobscript.$$ <<- EOF
	#
	# Setup scratch directory and setup input files
	#
	#
	SCR=${SCR}/\${SLURM_JOB_ID}
	mkdir -p \${SCR}
	if [ -d \${SCR} ]; then
	    cd \${SCR}
	EOF
	    if  [ ${APP} = "wrf" ]; then
	cat >> .slurmjobscript.$$ <<- EOF
	        for FILE in ${INPD}/${INP}/*
	        do
	            ln -s \${FILE} .
	        done
	EOF
	    elif [ -d ${INPD}/${INP} ]; then
	cat >> .slurmjobscript.$$ <<- EOF
	        rsync -a ${INPD}/${INP}/ .
	EOF
	    else
	cat >> .slurmjobscript.$$ <<- EOF
		    cp ${INPD}/${INP} .
	EOF
	    fi
	cat >> .slurmjobscript.$$ <<- EOF
	else
	    echo "Cannot create directory \${SCR}"
	    exit 1
	fi

	EOF
	
}

function submit_job ()
{
    #
    # Submit the job
    #
    #
    if [ "x${NODENAME}" != "x" ]; then
        RES=$( sbatch ${SLURM_OPTS} -w ${NODENAME} .slurmjobscript.$$ )
    else
        RES=$( sbatch ${SLURM_OPTS} .slurmjobscript.$$ )
    fi
    echo ${RES}
    RES=$( echo ${RES} | tail -1 | awk '{print $NF}' )
    mv .slurmjobscript.$$ slurmjobscript.${RES}
}
