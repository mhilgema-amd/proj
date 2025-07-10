# Slurm installation process

Author: Martin Hilgeman <martin.hilgeman@amd.com>
Date: 2025-03-05 12:38

## Preface

I am assuming an Ubuntu 24.04 installation, but it should work on all other 
Ubuntu versions as well.

## Install the Slurm packages

```shell
apt install slurm slurmd slurm-wlm slurmctld slurmdbd munge libmunge-dev
```

## Install the development packages

We need those to compile Open MPI with Slurm/PMI support.

```shell
apt install libslurm-dev
```

Slurm and Open MPI support three process managers:

1. PMI: The original PMI interface, developed by MPICH and adopted early
by Slurm. Rarely used today.
2. PMI2: An enhanced version of PMI, introduced to address scalability and
feature limitations of PMI-1. Native in Slurm since around 2013
(version 2.6+), and widely supported in modern Slurm deployments
3. PMIx: The new PMI interface, developed by Open MPI and adopted by Slurm
in 2018. This is the interface we will use.

Install the pmix development package:

```shell
apt install libpmix-dev libpmix-bin
```

## Installing auxiliary libraries

I am assuming that you have already installed ROCm on the system and that
`$ROCM_PATH` is set to something like `/opt/rocm` or `/opt/rocm-6.3.2`,
for example. I make ROCm available to my environment by adding the following:

```shell
module load rocm/6.3.0
```

### xpmem

```shell
git clone https://github.com/hpc/xpmem.git
cd xpmem
./autogen.sh
./configure --prefix=/opt/xpmem/git_3bcab55
sudo make install
```

Xpmem comes with its own kernel module which is built together with the source code

You can load it manually with:

```shell
sudo insmod /opt/xpmem/git_3bcab55/lib/modules/6.8.0-54-generic/kernel/xpmem/xpmem.ko
```

Verify that it has been loaded properly:

```shell
sudo dmesg|grep -i xpmem
[ 6822.726705] XPMEM kernel module v2.6.5 loaded
```

### UCX

Open MPI uses the UCX library for high-performance networking. UCX is a
communication library that provides support for high-performance networking
hardware. It is designed to be used by MPI libraries and other communication
libraries.

Install UCX as follows:

```shell
wget https://github.com/openucx/ucx/archive/refs/tags/v1.18.0.tar.gz
mv v1.18.0.tar.gz ucx-1.18.0.tar.gz
tar zxf ucx-1.18.0.tar.gz
cd ucx-1.18.0

./autogen.sh
if [ -d build ]; then rm -rf build; fi
mkdir build && cd build || exit 1
../contrib/configure-release \
    --prefix=/opt/ucx/rocm630/1.18.0 \
    --with-rocm=/opt/rocm-6.3.0 \
    --with-xpmem=/opt/xpmem/git_3bcab55 \
    2>&1 | tee log.configure || exit 1

make -j 2>&1 | tee make.log || exit 1
sudo make install 2>&1 | tee make.install.log || exit 1
```

### UCC

It is advisable to compile the Unified Collective (UCC) library, that will
give you highly scalable and performant collective operations for HPC, AI
and ML workloads.

Install UCC as follows:

```shell
git clone https://github.com/openucx/ucc.git
cd ucc

./autogen.sh
mkdir build && cd build || exit 1

../configure \
    --prefix=/opt/ucc/rocm630/git_5e555d7 \
    --with-ucx=/opt/ucx/rocm630/1.18.0 \
    --with-rocm=/opt/rocm-6.3.0 \
    --with-rccl=/opt/rocm-6.3.0 \
    2>&1 | tee log.configure || exit 1

make -j 2>&1 | tee log.make || exit 1
make install 2>&1 | tee log.make.install || exit 1
```


### hwloc

The hwloc library is used by Open MPI to determine the topology of the
machine. Install it as follows:

```shell
wget https://download.open-mpi.org/release/hwloc/v2.12/hwloc-2.12.0.tar.gz
tar zxf hwloc-2.12.0.tar.gz

cd hwloc-2.12.0
./configure \
    --prefix=/opt/hwloc/2.12.0 \
    2>&1 | tee log.configure || exit 1

make -j 8 2>&1 | tee log.make || exit 1
sudo make install 2>&1 | tee make.install.log || exit 1
```

## Download the latest Open MPI release

```shell
wget https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.7.tar.gz
```

## Unpack the archive and run the configure script

```shell
tar zxf openmpi-5.0.7.tar.gz
cd openmpi-5.0.7
```

I always build out of tree to keep the source tree clean:

```shell
mkdir build && cd build || exit 1
../configure \
    --prefix=/opt/openmpi/rocm630/5.0.7 \
    --enable-mpi1-compatibility \
    --enable-pmix-binaries \
    --with-pmix=internal \
    --with-hwloc=/opt/hwloc/2.12.0 \
    --with-slurm \
    --with-munge=/usr \
    --with-munge-libdir=/usr/lib/x86_64-linux-gnu \
    --with-ucx=/opt/ucx/rocm630/1.18.0 \
    --with-cma \
    --with-xpmem=/opt/xpmem/git_3bcab55 \
    --with-rocm=${ROCM_PATH} \
    --with-ucc=/opt/ucc/rocm630/git_5e555d7 \
    2>&1 | tee log.configure || exit 1

make -j 2>&1 | tee log.make || exit 1
sudo make install 2>&1 | tee log.make.install || exit 1
```

## Configuring Slurm (optional)

### Verify Slurm version

```shell
slurmd --version
```

In my case it outputs `slurm-wlm 23.11.4`

### Install munge for authentication

```shell
sudo apt install munge libmunge-dev
```

### Setup a random password for munge

```shell
dd if=/dev/urandom of=/etc/munge/munge.key bs=1 count=128
chmod 400 /etc/munge/munge.key
chown munge:munge /etc/munge/munge.key
```

Test the munge key:

```shell
munge -n | unmunge
STATUS:          Success (0)
ENCODE_HOST:     durc (192.168.0.94)
ENCODE_TIME:     2025-03-05 20:20:28 +0100 (1741202428)
DECODE_TIME:     2025-03-05 20:20:28 +0100 (1741202428)
TTL:             300
CIPHER:          aes128 (4)
MAC:             sha256 (5)
ZIP:             none (0)
UID:             root (0)
GID:             root (0)
LENGTH:          0
```

### Start the munge daemon

```shell
sudo systenctl enable munge
sudo systemctl start munge
```

### Check status

```shell
systemctl status munge
● munge.service - MUNGE authentication service
Loaded: loaded (/usr/lib/systemd/system/munge.service; enabled; preset: enabled)
Active: active (running) since Wed 2025-03-05 12:42:37 CET; 3h 4min ago
Docs: man:munged(8)
Main PID: 7502 (munged)
Tasks: 4 (limit: 57385)
Memory: 672.0K (peak: 1.6M)
CPU: 31ms
CGroup: /system.slice/munge.service
└─7502 /usr/sbin/munged

mrt 05 12:42:37 durc systemd[1]: Starting munge.service - MUNGE authentication service...
mrt 05 12:42:37 durc (munged)[7500]: munge.service: Referenced but unset environment variable evaluat>
mrt 05 12:42:37 durc systemd[1]: Started munge.service - MUNGE authentication service.
```

### Copy the default slurm.conf file to the system location

```shell
sudo cp cp /usr/share/doc/slurmctld/examples/slurm.conf.example /etc/slurm/slurm.conf
sudo chmod 644 /etc/slurm/slurm.conf
```

### Edit /etc/slurm/slurm.conf

Change the values of the following options to your liking:

```shell
ClusterName
SlurmctldHost
NodeName (for all the nodes in the cluster)
PartitionName
```

Also, we want to make PMIx to be the default MPI launcher. Add this to
`/etc/slurm/slurm.conf`:

```shell
MpiDefault=pmix
```

### Create required directories

```shell
sudo mkdir -p /var/spool/slurmctld /var/spool/slurmd /var/log/slurm
sudo chown slurm:slurm /var/spool/slurmctld /var/spool/slurmd
sudo chmod 755 /var/spool/slurmctld /var/spool/slurmd
sudo touch /var/log/slurm/slurmctld.log /var/log/slurm/slurmd.log
sudo chown slurm:slurm /var/log/slurm/slurmctld.log /var/log/slurm/slurmd.log
```

### Start the Slurm daeomen and slurm control daemon

```shell
sudo systenctl enable slurmd slurmctld
sudo systemctl start slurmd slurmctld
```

### Check status of the daemons

slurmd

```shell
systemctl status slurmd
● slurmd.service - Slurm node daemon
Loaded: loaded (/usr/lib/systemd/system/slurmd.service; enabled; preset: enabled)
Active: active (running) since Wed 2025-03-05 16:19:21 CET; 2min 55s ago
Docs: man:slurmd(8)
Main PID: 466932 (slurmd)
Tasks: 1
Memory: 1.4M (peak: 2.1M)
CPU: 17ms
CGroup: /system.slice/slurmd.service
└─466932 /usr/sbin/slurmd --systemd

mrt 05 16:19:21 durc systemd[1]: Starting slurmd.service - Slurm node daemon...
mrt 05 16:19:21 durc slurmd[466932]: slurmd: error: Node configuration differs from hardware: CPUs=16>
mrt 05 16:19:21 durc slurmd[466932]: slurmd: slurmd version 23.11.4 started
mrt 05 16:19:21 durc slurmd[466932]: slurmd: slurmd started on Wed, 05 Mar 2025 16:19:21 +0100
mrt 05 16:19:21 durc systemd[1]: Started slurmd.service - Slurm node daemon.
mrt 05 16:19:21 durc slurmd[466932]: slurmd: CPUs=16 Boards=1 Sockets=16 Cores=1 Threads=1 Memory=479>
```

slurmctld

```shell
● slurmctld.service - Slurm controller daemon
Loaded: loaded (/usr/lib/systemd/system/slurmctld.service; enabled; preset: enabled)
Active: active (running) since Wed 2025-03-05 16:03:20 CET; 1s ago
Docs: man:slurmctld(8)
Main PID: 466309 (slurmctld)
Tasks: 12
Memory: 2.1M (peak: 3.4M)
CPU: 8ms
CGroup: /system.slice/slurmctld.service
├─466309 /usr/sbin/slurmctld --systemd
└─466311 "slurmctld: slurmscriptd"

mrt 05 16:03:20 durc slurmctld[466309]: slurmctld: slurmctld version 23.11.4 started on cluster durc_>
mrt 05 16:03:20 durc systemd[1]: Started slurmctld.service - Slurm controller daemon.
mrt 05 16:03:20 durc slurmctld[466309]: slurmctld: No memory enforcing mechanism configured.
mrt 05 16:03:20 durc slurmctld[466309]: slurmctld: error: read_slurm_conf: default partition not set.
mrt 05 16:03:20 durc slurmctld[466309]: slurmctld: Recovered state of 1 nodes
mrt 05 16:03:20 durc slurmctld[466309]: slurmctld: Recovered information about 0 jobs
mrt 05 16:03:20 durc slurmctld[466309]: slurmctld: Recovered state of 0 reservations
mrt 05 16:03:20 durc slurmctld[466309]: slurmctld: read_slurm_conf: backup_controller not specified
mrt 05 16:03:20 durc slurmctld[466309]: slurmctld: select/cons_tres: select_p_reconfigure: select/con>
mrt 05 16:03:20 durc slurmctld[466309]: slurmctld: Running as primary controller
```

### Check node and partition

```shell
sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
local*       up   infinite      1   idle durc
```

### Compile a simple MPI test program and test with srun

```c
cat > hello_mpi.c << EOF
#include <stdio.h>
#include <mpi.h>

int main(int argc, char **argv) {
int i, rank, size;

MPI_Init(&argc,&argv);
MPI_Comm_rank(MPI_COMM_WORLD, &rank);
MPI_Comm_size(MPI_COMM_WORLD, &size);

fprintf(stdout, "Hello from %d out of %d.\n", rank, size);

MPI_Finalize();
}
EOF
```

Compile the program:

```shell
mpicc hello_mpi.c -o hello_mpi.exe
```

Run with `srun`

```shell
srun -n 8 ~/work/simple_mpi.exe
Hello from 5 out of 8.
Hello from 2 out of 8.
Hello from 6 out of 8.
Hello from 1 out of 8.
Hello from 3 out of 8.
Hello from 7 out of 8.
Hello from 4 out of 8.
Hello from 0 out of 8.
```
