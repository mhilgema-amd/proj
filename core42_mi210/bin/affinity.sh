#!/usr/bin/bash 

# 
# Node setup 
# 
sleep 2
HOST=$(hostname -s) 
NCORES=$(grep -ce '^processor' /proc/cpuinfo) 
NUMA_NODES=$(numactl --hardware | grep available: | awk '{print $2}') 
NGPUS=$( rocm-smi --showserial | grep "GPU" | wc -l ) 
PPN=${OMPI_COMM_WORLD_LOCAL_SIZE}
export OMP_NUM_THREADS=$(( NCORES / OMPI_COMM_WORLD_LOCAL_SIZE )) 

MY_GPU=$(( OMPI_COMM_WORLD_LOCAL_RANK % NGPUS )) 
# 
# Local MPI rank to GPU and NIC mapping 
# 
case "${MY_GPU}" in 
0) 
export UCX_NET_DEVICES=rocep9s0f0:1 
;; 
1) 
export UCX_NET_DEVICES=rocep9s0f0:1 
;; 
2) 
export UCX_NET_DEVICES=rocep67s0f0:1 
;; 
3) 
export UCX_NET_DEVICES=rocep67s0f0:1 
;; 
4) 
export UCX_NET_DEVICES=rocep137s0f0:1 
;; 
5) 
export UCX_NET_DEVICES=rocep137s0f0:1 
;; 
6) 
export UCX_NET_DEVICES=rocep201s0f0:1 
;; 
7) 
export UCX_NET_DEVICES=rocep201s0f0:1 
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
export OMPI_MCA_pml=ucx

echo "$0: pinning MPI rank ${OMPI_COMM_WORLD_RANK} local rank ${OMPI_COMM_WORLD_LOCAL_RANK} on $(hostname) to CPU cores ${START_CPU}-${END_CPU} NUMA=${NUMA_DOMAIN} GPU=${MY_GPU} NIC=${UCX_NET_DEVICES}" 

exec ${AFFINITY} $*
 
