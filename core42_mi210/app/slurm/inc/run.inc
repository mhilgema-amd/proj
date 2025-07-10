#!/bin/bash
#

function run_app ()
{
	MPI_ARGS="${MPI_ARGS} -np ${NPES}"

	cat >> .slurmjobscript.$$ <<- EOF

		# 
		# Run the benchmark
		#
		#
		env > \${SCR}/env.txt 2>&1 
		echo "Scratch directory is: \${SCR}"
		echo "Executable is: ${EXE}"
		echo
		RUNCMD="${F1COUNT} ${MPIRUN} ${MPI_ARGS} ${APS} ${VTUNE2} ${AFFINITY} ${PERF} ${OPROFILE} ${UPROF} ${VTUNE1} ${EXE} ${EXE_ARGS}"
		echo "\${RUNCMD}"
		eval "mytime \${RUNCMD} | tee ${APP}.${NPES}.out 2>&1"

	EOF
}

function run_sysinfo()
{
	cat >> .slurmjobscript.$$ <<- EOF

		module list

		#
		# Gather system information from all the nodes
		#
		#
		for NNODE in \$( scontrol show hostnames ); do
		    ssh \${NNODE} "module load sysinfo; sysinfo" > \${SCR}/sysinfo.\${NNODE}.txt < /dev/null &
		done
		wait

	EOF
}
