#!/bin/bash
#

function init_application ()
{
    APP=openfoam
    VERSION=v1912
    BUILD=
    NSOCK=2
    MPI=openmpi
    COMPILER=intel19
    PREFIX=${HOME}/app/${APP}/work/${VERSION}/${BUILD}
    INPD=${HOME}/app/${APP}/inp
    INP=motorBike_12.8M
    EXE=simpleFoam
    EXE_ARGS="-parallel"
    EXTRA_OPTION=
    TEXT_EXTRA_OPTION1="<not used>           "
    TEXT_EXTRA_OPTION2="<not used>           "
    TEXT_EXTRA_OPTION3="<not used>           "
}

function post_application ()
{
    #
    # CHPC 2021 benchmark setup
    #
    if [ ${INP} = "SimpleBenchMarkLarge2006" ]; then
		cat >> .slurmjobscript.$$ <<- EOF
			#
			# OpenFOAM number of iterations per hour
			#
			BEGINTIME=\$( grep 'ClockTime' ${APP}.${NPES}.out | head -1 | awk '{print \$7}' )
			ENDTIME=\$( grep 'ClockTime' ${APP}.${NPES}.out | tail -1 | awk '{print \$7}' )
			ITER_HOUR=\$( echo "scale = 2; 3600 / (( \${ENDTIME} - \${BEGINTIME} ) / 500 )" | bc )
			echo "OpenFOAM iterations/hour: \${ITER_HOUR}"
		EOF
    else
        echo
    fi
}

function extra_setup ()
{
    #
    # CHPC 2021 benchmark setup
    #
    if [ ${INP} = "SimpleBenchMarkLarge2006" ]; then
		cat >> .slurmjobscript.$$ <<- EOF
			#
			# OpenFOAM job decomposition
			#
			echo "FoamFile" > system/decomposeParDict
			echo "{"  >> system/decomposeParDict
			echo "  version             2.0;" >> system/decomposeParDict
			echo "  format            ascii;" >> system/decomposeParDict
			echo "  class        dictionary;" >> system/decomposeParDict
			echo "  object decomposeParDict;" >> system/decomposeParDict
			echo "}"  >> system/decomposeParDict
			echo "numberOfSubdomains " ${NPES}";" >> system/decomposeParDict
			echo "method scotch;" >> system/decomposeParDict

			#sed -i 's/d                    uniform -0.5/zGround              uniform -0.5/g' 0/include/ABLConditions
			#sed -i 's/atmNutkWallFunction/nutkAtmRoughWallFunction/g' 0/nut

			mpirun -np 1 decomposePar -force 2>&1 | tee decompose.out.${NPES}

		EOF
    fi
}
