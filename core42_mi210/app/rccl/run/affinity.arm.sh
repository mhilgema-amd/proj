#!/usr/bin/bash 
export OMPI_MCA_pml=ucx
export OMPI_MCA_btl=^openib

#export UCX_IB_GID_INDEX=3
export NCCL_IB_GID_INDEX=3
export NCCL_NET_GDR_LEVEL=3
#export NCCL_IB_PCI_RELAXED_ORDERING=1
#export HSA_DISABLE_CACHE=1
#export HSA_FORCE_FINE_GRAIN_PCIE=1
#export HIP_FORCE_DEV_KERNARG=1
#export NCCL_NET_SHARED_BUFFERS=0
#export NCCL_ALGO=Ring
#export NCCL_PROTO=Simple
export NCCL_SOCKET_IFNAME=enp69s0f0np0
export NCCL_IB_HCA=rocep9s0f0:1,rocep67s0f0:1,rocep137s0f0:1,rocep201s0f0:1
export NCCL_MIN_NCHANNELS=14
export NCCL_MAX_NCHANNELS=14
#export RCCL_ENABLE_INTRANET=1
export NCCL_DEBUG="info"
#export NCCL_DEBUG_SUBSYS="INIT,ENV,GRAPH,NET,TUNING"
export NCCL_DEBUG_SUBSYS="INIT,GRAPH"

export NCCL_RINGS="\
        N1 2 3 0 1 4 5 6 7 N3|\
        N0 1 0 3 2 7 6 4 5 N2|\
        N0 0 1 2 3 6 5 7 4 N2|\
        N1 3 2 1 0 5 7 4 6 N3|\
        N2 5 4 6 7 2 3 0 1 N0|\
        N2 4 7 5 6 3 2 1 0 N0|\
        N2 5 4 6 7 2 3 0 1 N0|\
        N3 6 4 7 5 0 1 2 3 N1|"
exec $*
