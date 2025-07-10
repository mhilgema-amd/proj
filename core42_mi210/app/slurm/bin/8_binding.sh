#!/bin/bash

if [[ -n ${OMPI_COMM_WORLD_LOCAL_RANK+x} ]]; then
  globalRank=$OMPI_COMM_WORLD_RANK
  globalSize=$OMPI_COMM_WORLD_SIZE
  rank=$OMPI_COMM_WORLD_LOCAL_RANK
  size=$OMPI_COMM_WORLD_LOCAL_SIZE
elif [[ -n ${SLURM_LOCALID+x} ]]; then
  globalRank=$SLURM_PROCID
  globalSize=$SLURM_NTASKS
  rank=$SLURM_LOCALID
  size=$SLURM_TASKS_PER_NODE
  #Slurm can return a string like "2(x2),1". Get the first number
  size=$(echo $size | sed -r 's/^([^.]+).*$/\1/; s/^[^0-9]*([0-9]+).*$/\1/')
fi

dev=$(( $rank %2 ))

export UCX_NET_DEVICES=mlx5_$dev:1
export HIP_VISIBLE_DEVICES=$dev

if [[ $dev -eq 0 ]]; then
  omp_places={0,1,2,3,4,5,6,7}
else
  omp_places={24,25,26,27,28,29,30,31}
fi

coretobind=$(( 24 * $dev  ))
coretobindend=$(( 24 * $dev + 23  ))

#optional
export OMP_NUM_THREADS=8
export OMP_PLACES=${omp_places}
export OMP_PROC_BIND=true
export GOMP_CPU_AFFINITY=$coretobind-$coretobindend

echo "rank $globalRank / $globalSize , cores $coretobind-$coretobindend , GPU $dev, NIC $UCX_NET_DEVICES $( hostname )"

numactl --all -C $coretobind-$coretobindend -m $dev  $@

