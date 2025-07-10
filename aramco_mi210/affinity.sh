#!/usr/bin/bash
#
# Author:      Martin Hilgeman <martin.hilgeman@amd.com>
# Date:        04/17/2025 14:31:36
# Description: Simple affinity script to work with Open MPI
#


#
# Node setup
#
HOST=$(hostname -s)
NCORES=$(grep -ce '^processor' /proc/cpuinfo)
NUMA_NODES=$(numactl --hardware | grep available: | awk '{print $2}')
NSOCK=$(sort -u /sys/devices/system/cpu/cpu*/topology/physical_package_id | wc -l)
NGPUS=$( rocm-smi --showserial | grep "GPU" | wc -l )
HAVE_SMT=$(cat /sys/devices/system/cpu/smt/active)


PPN=${OMPI_COMM_WORLD_LOCAL_SIZE}
if [ ! -n "${PPN}" ]; then
    echo "$0: error: OMPI_COMM_WORLD_LOCAL_SIZE is not set"
    exit 1
fi
export OMP_NUM_THREADS=$(( NCORES / OMPI_COMM_WORLD_LOCAL_SIZE ))

MOD=$(( OMPI_COMM_WORLD_LOCAL_RANK % NGPUS ))

case "${MOD}" in
    0)
        if [ -n "${MY_GPU0}" ]; then
            MY_GPU=${MY_GPU0}
        else
            MY_GPU=${MOD}
        fi
        ;;
    1)
        if [ -n "${MY_GPU1}" ]; then
            MY_GPU=${MY_GPU1}
        else
            MY_GPU=${MOD}
        fi
        ;;
    2)
        if [ -n "${MY_GPU2}" ]; then
            MY_GPU=${MY_GPU2}
        else
            MY_GPU=${MOD}
        fi
        ;;
    3)
        if [ -n "${MY_GPU3}" ]; then
            MY_GPU=${MY_GPU3}
        else
            MY_GPU=${MOD}
        fi
        ;;
    4)
        if [ -n "${MY_GPU4}" ]; then
            MY_GPU=${MY_GPU4}
        else
            MY_GPU=${MOD}
        fi
        ;;
    5)
        if [ -n "${MY_GPU3}" ]; then
            MY_GPU=${MY_GPU3}
        else
            MY_GPU=${MOD}
        fi
        ;;
    6)
        if [ -n "${MY_GPU3}" ]; then
            MY_GPU=${MY_GPU3}
        else
            MY_GPU=${MOD}
        fi
        ;;
    7)
        if [ -n "${MY_GPU7}" ]; then
            MY_GPU=${MY_GPU7}
        else
            MY_GPU=${MOD}
        fi
        ;;
   *)
        echo "$0: error: invalid local rank ${OMPI_COMM_WORLD_LOCAL_RANK}"
        exit 1
        ;;
esac

#
# GPU to NIC mapping
#
case "${MY_GPU}" in
    0)
        export UCX_NET_DEVICES=bnxt_re4:1
        ;;
    1)
        export UCX_NET_DEVICES=bnxt_re5:1
        ;;
    2)
        export UCX_NET_DEVICES=bnxt_re2:1
        ;;
    3)
        export UCX_NET_DEVICES=bnxt_re3:1
        ;;
    4)
        export UCX_NET_DEVICES=bnxt_re8:1
        ;;
    5)
        export UCX_NET_DEVICES=bnxt_re9:1
        ;;
    6)
        export UCX_NET_DEVICES=bnxt_re6:1
        ;;
    7)
        export UCX_NET_DEVICES=bnxt_re7:1
        ;;
   *)
        echo "$0: error: invalid GPU ${GPU}"
        exit 1
        ;;
esac

START_CPU=$(( MY_GPU * OMP_NUM_THREADS ))
END_CPU=$(( START_CPU + OMP_NUM_THREADS - 1 ))
NUMA_DOMAIN=$( rocm-smi --showtoponuma | grep "GPU\[${MY_GPU}\].*Node:" | awk '{print $NF}' )
AFFINITY="numactl --all -C ${START_CPU}-${END_CPU} --cpubind=${NUMA_DOMAIN} --membind=${NUMA_DOMAIN}"

export HIP_VISIBLE_DEVICES=${MY_GPU}

echo "$0: pinning MPI rank ${OMPI_COMM_WORLD_RANK} local rank ${OMPI_COMM_WORLD_LOCAL_RANK} on $(hostname) to CPU cores ${START_CPU}-${END_CPU} NUMA=${NUMA_DOMAIN} GPU=${MY_GPU} NIC=${UCX_NET_DEVICES}"

exec ${AFFINITY} $*
