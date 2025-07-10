# ROCm and AMDGPU driver on Conductor node smci350-zts-gtu-e14-05

Author: Martin Hilgeman <mhilgema@amd.com>
Date: 07/07/2025

## Install the prerequisites

```bash
sudo apt install python3-setuptools python3-wheel
```

## Register ROCm repositories

### Add the package signing key for the ROCm repository.

```bash
# Make the directory if it doesn't exist yet.
# This location is recommended by the distribution maintainers.
sudo mkdir --parents --mode=0755 /etc/apt/keyrings
# Download the key, convert the signing-key to a full
# keyring required by apt and store in the keyring directory.
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | \
  gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null
```

### Register ROCm packages

```bash
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/7.0_alpha jammy main" \
  | sudo tee /etc/apt/sources.list.d/rocm.list

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/graphics/7.0_alpha/ubuntu jammy main" \
  | sudo tee /etc/apt/sources.list.d/rocm-graphics.list

echo -e 'Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600' \
  | sudo tee /etc/apt/preferences.d/rocm-pin-600
sudo apt update
```

### Upgrade the OS packages to their latest version

```bash
sudo apt upgrade
```

## Install ROCm

```bash
sudo apt install rocm
```

The amdgpu driver is installed as a dependency of the ROCm package:

```bash
dpkg -l amdgpu-dkms
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name           Version                         Architecture Description
+++-==============-===============================-============-==============================>
ii  amdgpu-dkms    1:6.14.8.30100000-2175180.22.04 all          amdgpu driver in DKMS format.
lines 1-6/6 (END)
```

## Load amdgpu driver

```bash
sudo modprobe amdgpu

sudo rocm-smi


============================================= ROCm System Management Interface =============================================
======================================================= Concise Info =======================================================
Device  Node  IDs              Temp        Power     Partitions          SCLK    MCLK     Fan  Perf  PwrCap   VRAM%  GPU%  
              (DID,     GUID)  (Junction)  (Socket)  (Mem, Compute, ID)                                                    
============================================================================================================================
0       3     0x75a0,   39903  59.0°C      256.0W    NPS1, SPX, 0        157Mhz  1900Mhz  0%   auto  1000.0W  0%     0%    
1       5     0x75a0,   22482  62.0°C      258.0W    NPS1, SPX, 0        148Mhz  1900Mhz  0%   auto  1000.0W  0%     0%    
2       4     0x75a0,   46071  57.0°C      252.0W    NPS1, SPX, 0        148Mhz  1900Mhz  0%   auto  1000.0W  0%     0%    
3       2     0x75a0,   32762  67.0°C      264.0W    NPS1, SPX, 0        147Mhz  1900Mhz  0%   auto  1000.0W  0%     0%    
4       7     0x75a0,   15294  59.0°C      257.0W    NPS1, SPX, 0        147Mhz  1900Mhz  0%   auto  1000.0W  0%     0%    
5       9     0x75a0,   63411  67.0°C      264.0W    NPS1, SPX, 0        146Mhz  1900Mhz  0%   auto  1000.0W  0%     0%    
6       8     0x75a0,   5014   61.0°C      257.0W    NPS1, SPX, 0        152Mhz  1900Mhz  0%   auto  1000.0W  0%     0%    
7       6     0x75a0,   57243  64.0°C      258.0W    NPS1, SPX, 0        146Mhz  1900Mhz  0%   auto  1000.0W  0%     0%    
============================================================================================================================
=================================================== End of ROCm SMI Log ====================================================
```

## Environment modules

For running HPC applications, it is very beneficial to install environment-modules. The rocHPL package that is part of AGFHC has Open MPI bundled in. We are going to unlock the Open MPI installation by writing an environment module file for it.

An example modulefile for rocHPL that is installed in `/opt/modulefiles`

```tcl
#%Module1.0#####################################################################
##
## rocHPL
##
set             module_prefix         /opt
set             vendor                amd

set             app                   rochpl
set             framework             rocm700
set             version               7.0.0

proc ModulesHelp { } {
    puts stderr "\tAdds $app $version to environment paths\n"
}

module-whatis   "loads $app $version module"

set             root                  $module_prefix/$vendor/$app

prepend-path    PATH                  $root/build:$root/build/bin

set prereq1     $vendor/rocm/7.0.0
set prereq2     $vendor/ucx/1.16.0
set prereq3     $vendor/openmpi/5.0.3

if { [module-info mode load] } {
    if { ! [ is-loaded $prereq1 ] } {
        module load $prereq1
    }
    if { ! [ is-loaded $prereq2 ] } {
        module load $prereq2
    }
    if { ! [ is-loaded $prereq3 ] } {
        module load $prereq3
    }
}

if { [module-info mode remove ] } {
    if { [ is-loaded $prereq1 ] } {
        module unload $prereq1
    }
    if { [ is-loaded $prereq2 ] } {
        module unload $prereq2
    }
    if { [ is-loaded $prereq3 ] } {
        module unload $prereq3
    }
}
```

Load the modules environment and add the modules directory to the path

```bash
. /etc/profile.d/modules.sh
module use /opt/modulefiles
module avail
-------------------------------------- /opt/modulefiles ---------------------------------------
amd/agfhc/1.23.2   amd/openmpi/5.0.3  amd/ucx/1.16.0  
amd/minihpl/0.1.0  amd/rochpl/7.0.0   rocm/7.0.0      

------------------------------- /usr/share/modules/modulefiles --------------------------------
dot  module-git  module-info  modules  null  use.own  

Key:
loaded  modulepath
```

3.2 Check GPU presence

```bash
mhilgema@smci350-zts-gtu-e14-05:~$ lspci|grep accelerators
05:00.0 Processing accelerators: Advanced Micro Devices, Inc. [AMD/ATI] Device 75a0
15:00.0 Processing accelerators: Advanced Micro Devices, Inc. [AMD/ATI] Device 75a0
65:00.0 Processing accelerators: Advanced Micro Devices, Inc. [AMD/ATI] Device 75a0
75:00.0 Processing accelerators: Advanced Micro Devices, Inc. [AMD/ATI] Device 75a0
85:00.0 Processing accelerators: Advanced Micro Devices, Inc. [AMD/ATI] Device 75a0
95:00.0 Processing accelerators: Advanced Micro Devices, Inc. [AMD/ATI] Device 75a0
e5:00.0 Processing accelerators: Advanced Micro Devices, Inc. [AMD/ATI] Device 75a0
f5:00.0 Processing accelerators: Advanced Micro Devices, Inc. [AMD/ATI] Device 75a0
```

**PASSED** all 8 GPUs are found.

3.3 Check GPU Link Speed on Width on PCIe bus

```bash
sudo lspci -d 1002:75a0 -vvv | grep -e DevSta -e LnkSta
		DevSta:	CorrErr- NonFatalErr- FatalErr- UnsupReq- AuxPwr- TransPend-
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
		LnkSta2: Current De-emphasis Level: -3.5dB, EqualizationComplete- EqualizationPhase1-
		DevSta:	CorrErr- NonFatalErr- FatalErr- UnsupReq- AuxPwr- TransPend-
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
		LnkSta2: Current De-emphasis Level: -3.5dB, EqualizationComplete- EqualizationPhase1-
		DevSta:	CorrErr- NonFatalErr- FatalErr- UnsupReq- AuxPwr- TransPend-
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
		LnkSta2: Current De-emphasis Level: -3.5dB, EqualizationComplete- EqualizationPhase1-
		DevSta:	CorrErr- NonFatalErr- FatalErr- UnsupReq- AuxPwr- TransPend-
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
		LnkSta2: Current De-emphasis Level: -3.5dB, EqualizationComplete- EqualizationPhase1-
		DevSta:	CorrErr- NonFatalErr- FatalErr- UnsupReq- AuxPwr- TransPend-
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
		LnkSta2: Current De-emphasis Level: -3.5dB, EqualizationComplete- EqualizationPhase1-
		DevSta:	CorrErr- NonFatalErr- FatalErr- UnsupReq- AuxPwr- TransPend-
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
		LnkSta2: Current De-emphasis Level: -3.5dB, EqualizationComplete- EqualizationPhase1-
		DevSta:	CorrErr- NonFatalErr- FatalErr- UnsupReq- AuxPwr- TransPend-
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
		LnkSta2: Current De-emphasis Level: -3.5dB, EqualizationComplete- EqualizationPhase1-
		DevSta:	CorrErr- NonFatalErr- FatalErr- UnsupReq- AuxPwr- TransPend-
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
		LnkSta2: Current De-emphasis Level: -3.5dB, EqualizationComplete- EqualizationPhase1-
```

**PASSED**

- link speed is 32 GT/s
- with is x16.
- No `FatalErr+` values

### 3.4 Monitoring Utilization Metrics

```bash
amd-smi monitor -putm
GPU  POWER  PWR_CAP   GPU_T   MEM_T   GFX_CLK   GFX%   MEM%  MEM_CLOCK
  0  251 W   1000 W   55 °C   43 °C   144 MHz    0 %    0 %   1900 MHz
  1  258 W   1000 W   58 °C   47 °C   163 MHz    0 %    0 %   1900 MHz
  2  251 W   1000 W   54 °C   43 °C   145 MHz    0 %    0 %   1900 MHz
  3  257 W   1000 W   61 °C   48 °C   145 MHz    0 %    0 %   1900 MHz
  4  257 W   1000 W   55 °C   43 °C   144 MHz    0 %    0 %   1900 MHz
  5  257 W   1000 W   61 °C   49 °C   145 MHz    0 %    0 %   1900 MHz
  6  256 W   1000 W   56 °C   45 °C   145 MHz    0 %    0 %   1900 MHz
  7  257 W   1000 W   59 °C   48 °C   149 MHz    0 %    0 %   1900 MHz
```

**PASSED**

- `GFX%` and `MEM%` are 0% because no GPU workload is running
- `GFX_CLK` is lower than 200 MHz
  `MEM_CLOCK` is 1900 MHz

### 3.5	Check the System Kernel Logs for Other Errors

```bash
sudo dmesg -T | grep amdgpu | grep -i 'error\|warn\|fail\|exception'
```

**PASSED**

- No errors displayed

## 4.1 AGHFC installation

### 4.1.1 Install rocm-validation-suite

rocm-validation-suite is required for AGFHC.

```bash
sudo apt install rocm-validation-suite
```

### 4.1.2 Get AGFHC

Get the latest version of AGFHC from the [AGFHC repository](https://github.amd.com/dctools/agfhc/releases)

```bash
set -o pipefail
mkdir -p ${HOME}/martinh/app/agfhc/src && cd ${HOME}/martinh/app/agfhc/src || exit 1
wget https://atlartifactory.amd.com:8443/artifactory/HW-AGFHCRelease-REL-LOCAL/1.23.2/mi300x/agfhc-mi300x_1.23.2_ub2204.tar.bz2

Unpack and install:

```bash
tar jxf ../src/agfhc-mi300x_1.23.2_ub2204.tar.bz2 
sudo ./install 

AGFHC tool is being installed... Please wait!

ROCm version 7.0.0 is detected.

Installing AGFHC packages ...
Installation successful!

Summary of installation:

Package Name              Status          Version                  
------------------------- --------------- -------------------------
agfhc                     Installed       1.23.2                   
firexs2                   Installed       2.0.0.0-jammy            
transferbench             Installed       1.62                     
rochpl                    Installed       7.0.0-03730d0            
minihpl                   Installed       0.1.0-8f5f175            

Installation path: /opt/amd/agfhc

AGFHC Installation Succeeded!
```

### 4.1.3 Run an example AGFHC test

```bash
/opt/amd/agfhc/agfhc -r /opt/amd/agfhc/recipes/mi350x/all_lvl1.yml 
Log Directory: /home/mhilgema/agfhc/logs/agfhc_20250707-050239
Product: MI350X | GPUs: 8 | Mode: BM SPX NPS1 | Checks: dmesg- ras+ perf-

The following tests will be run:
  Test               Title                     Mode                 Approximate Time
  gfx_bf16ri         GFX bf16 rand int         1 iteration                   0:01:20
  gfx_fp16ri         GFX fp16 rand int         1 iteration                   0:01:20
  gfx_fp8ri          GFX fp8 rand int          1 iteration                   0:01:20
  hbm_bw             HBM BW                    1 iteration                   0:01:05
  xgmi_a2a           XGMI BW A2A               1 iteration                   0:00:13
                                                                           ---------
                                                                   Total:   00:05:18

Executing tests:
  GFX bf16 rand int
    PASS: gfx_bf16ri-1-1                  [00:01:08/00:01:20]
  GFX fp16 rand int
    PASS: gfx_fp16ri-1-1                  [00:01:08/00:01:20]
  GFX fp8 rand int
    PASS: gfx_fp8ri-1-1                   [00:01:08/00:01:20]
  HBM BW
    PASS: hbm_bw-1-1                      [00:01:02/00:01:05]
  XGMI BW A2A
    PASS: xgmi_a2a-1-1                    [00:00:11/00:00:13]

Summary:
  Tests: 5 Total, 5 Executed, 0 Skipped | All Tests Passed
  Total Time: 00:04:44
  Log directory: /home/mhilgema/agfhc/logs/agfhc_20250707-050239
Program exiting with return code AGFHC_SUCCESS [0]
```

## 5 Performance benchmarking

### 5.1.1 TransferBench qualification

Install the prerequisites for TransferBench:

```bash
sudo apt-get install libnuma-dev rocm-bandwidth-test cmake
```

Transferbench additionally needs cmake to build and libibverbs-dev (for NIC related tests):

```bash
sudo apt install cmake libibverbs-dev
```

Build TransferBench as follows:

```bash
module load rocm/7.0.0

git clone https://github.com/ROCm/TransferBench.git

cd TransferBench

#
# Add support for ROCm 7.0.0 cmake build tools and MI350X
#
sed -i '/set(DEFAULT_GPUS/ifind_package(ROCmCMakeBuildTools)' CMakeLists.txt
sed -i '/gfx942/a\ \ \ \ \ \ gfx950' CMakeLists.txt

mkdir build && cd build

cmake \
    -DCMAKE_INSTALL_PREFIX=/opt/transferbench \
    -DCMAKE_CXX_COMPILER=hipcc \
    ..

make 2>&1 | tee log.make
make install 2>&1 | tee log.make.install

rsync -a examples /opt/transferbench/examples
```

#### 5.1.1.1	All-to-All

```bash
TransferBench a2a
...
Summary: [268435456 bytes per Transfer] [GFX:8] [1 Read(s) 1 Write(s)]
===========================================================================
SRC\DST  GPU 00     GPU 01     GPU 02     GPU 03     GPU 04     GPU 05     GPU 06     GPU 07        STotal      Actual
GPU 00      N/A     50.732     51.478     53.114     51.178     50.907     50.684     50.996       359.089     354.785
GPU 01   51.083        N/A     52.957     50.854     51.395     51.162     51.050     51.043       359.544     355.981
GPU 02   51.088     53.446        N/A     51.342     50.888     51.300     51.234     51.445       360.743     356.218
GPU 03   52.899     51.319     51.134        N/A     50.874     51.295     51.191     50.916       359.629     356.121
GPU 04   51.133     51.277     51.145     51.263        N/A     51.098     51.041     52.865       359.822     357.285
GPU 05   51.185     50.992     51.319     50.922     51.126        N/A     53.104     51.351       359.999     356.455
GPU 06   51.065     51.167     50.888     50.959     51.458     53.114        N/A     51.364       360.016     356.214
GPU 07   51.333     51.142     51.058     51.339     53.260     51.402     50.978        N/A       360.512     356.846

RTotal  359.786    360.074    359.978    359.793    360.180    360.278    359.282    359.981      2879.354     354.785     357.285

Average   bandwidth (GPU Timed):   51.417 GB/s
Aggregate bandwidth (GPU Timed): 2879.354 GB/s
Aggregate bandwidth (CPU Timed): 2671.564 GB/s
```

#### 5.1.1.2	Peer-to-Peer

```bash
TransferBench p2p
Bytes Per Direction 268435456
....
Unidirectional copy peak bandwidth GB/s [Local read / Remote write] (GPU-Executor: GFX)
 SRC+EXE\DST    CPU 00    CPU 01       GPU 00    GPU 01    GPU 02    GPU 03    GPU 04    GPU 05    GPU 06    GPU 07
  CPU 00  ->     92.21    102.51        45.11     45.16     45.13     45.07     45.06     45.11     44.64     45.05
  CPU 01  ->    104.88     90.09        44.74     44.81     44.76     44.77     44.78     44.83     44.83     44.77

  GPU 00  ->     55.47     55.54      2132.28     57.39     57.69     57.46     57.46     57.65     57.42     57.62
  GPU 01  ->     55.59     55.66        57.41   2152.51     57.58     57.52     57.65     57.37     57.65     57.50
  GPU 02  ->     55.60     55.61        57.41     57.50   2145.75     57.62     57.29     57.55     57.30     57.63
  GPU 03  ->     54.18     54.24        57.48     57.75     57.57   2150.49     57.61     57.48     57.38     57.36
  GPU 04  ->     55.52     55.53        57.38     57.66     57.37     57.72   2122.07     57.41     57.65     57.46
  GPU 05  ->     55.60     55.62        57.64     57.33     57.60     57.38     57.57   2150.67     57.51     57.43
  GPU 06  ->     54.41     54.57        57.41     57.68     57.43     57.31     57.67     57.62   2163.46     57.63
  GPU 07  ->     55.43     55.45        57.69     46.66     57.51     57.34     57.38     57.56     57.42   2154.14
                           CPU->CPU  CPU->GPU  GPU->CPU  GPU->GPU
Averages (During UniDir):    103.69     44.91     55.25     57.32

Bidirectional copy peak bandwidth GB/s [Local read / Remote write] (GPU-Executor: GFX)
     SRC\DST    CPU 00    CPU 01       GPU 00    GPU 01    GPU 02    GPU 03    GPU 04    GPU 05    GPU 06    GPU 07
  CPU 00  ->       N/A     88.77        44.81     44.81     44.76     44.78     44.77     44.76     44.81     44.74
  CPU 00 <-        N/A     89.79        55.10     55.03     54.94     53.93     55.14     55.05     53.77     55.14
  CPU 00 <->       N/A    178.56        99.90     99.84     99.70     98.71     99.90     99.81     98.58     99.87

  CPU 01  ->     88.50       N/A        44.36     44.33     44.39     44.28     44.38     44.39     44.43     44.42
  CPU 01 <-      88.29       N/A        55.10     55.04     54.96     53.91     55.15     55.06     53.75     55.13
  CPU 01 <->    176.79       N/A        99.45     99.37     99.35     98.19     99.53     99.45     98.18     99.55


  GPU 00  ->     55.02     54.96          N/A     54.69     54.91     54.71     54.52     55.02     54.74     54.88
  GPU 00 <-      44.71     44.45          N/A     54.61     54.72     54.58     54.52     54.96     54.53     54.82
  GPU 00 <->     99.73     99.41          N/A    109.30    109.63    109.29    109.04    109.99    109.26    109.70

  GPU 01  ->     55.08     55.11        54.68       N/A     54.60     54.93     54.83     54.64     54.87     54.66
  GPU 01 <-      44.74     44.41        54.63       N/A     54.63     54.86     54.80     54.63     54.82     54.57
  GPU 01 <->     99.82     99.52       109.30       N/A    109.23    109.80    109.63    109.27    109.68    109.23

  GPU 02  ->     55.12     55.14        54.60     54.57       N/A     54.88     54.68     54.88     54.67     54.93
  GPU 02 <-      44.74     44.31        54.90     54.59       N/A     54.99     54.56     54.73     54.60     54.87
  GPU 02 <->     99.86     99.45       109.50    109.16       N/A    109.86    109.24    109.62    109.27    109.80

  GPU 03  ->     53.83     53.83        54.54     54.89     54.91       N/A     54.93     54.69     38.96     54.55
  GPU 03 <-      44.74     44.29        54.77     54.91     54.92       N/A     54.80     54.70     40.37     54.48
  GPU 03 <->     98.57     98.12       109.31    109.80    109.83       N/A    109.73    109.40     79.33    109.03

  GPU 04  ->     54.95     55.08        54.55     54.82     54.61     54.68       N/A     54.71     54.97     54.68
  GPU 04 <-      44.75     44.45        54.57     54.88     54.79     54.85       N/A     54.90     54.84     54.57
  GPU 04 <->     99.70     99.52       109.11    109.70    109.40    109.52       N/A    109.61    109.81    109.26

  GPU 05  ->     55.12     55.13        54.97     54.52     54.66     54.58     54.83       N/A     54.68     54.79
  GPU 05 <-      44.76     44.37        54.94     54.61     54.91     54.63     54.60       N/A     54.47     54.81
  GPU 05 <->     99.88     99.50       109.91    109.14    109.57    109.21    109.43       N/A    109.14    109.60

  GPU 06  ->     53.92     53.94        54.60     54.75     54.58     54.39     54.83     54.68       N/A     54.88
  GPU 06 <-      44.69     44.37        54.64     54.89     54.65     54.64     54.98     54.66       N/A     54.67
  GPU 06 <->     98.61     98.30       109.24    109.65    109.23    109.03    109.80    109.34       N/A    109.55

  GPU 07  ->     54.96     54.96        54.93     54.79     54.96     54.55     54.53     54.88     54.66       N/A
  GPU 07 <-      44.74     44.46        54.88     37.99     54.90     54.62     54.69     54.65     54.84       N/A
  GPU 07 <->     99.70     99.42       109.81     92.79    109.86    109.17    109.22    109.53    109.50       N/A
                           CPU->CPU  CPU->GPU  GPU->CPU  GPU->GPU
Averages (During  BiDir):     88.84     49.67     49.66     54.32
```

#### 5.1.1.3	TransferBench Default ConfigFile

A standard TransferBench test with the default configuration file fails on MI350X GPUs, due to an invalid device function:

```bash
TransferBench /opt/transferbench/rocm700/git_2d0ecaa/share/examples/example.cfg 
TransferBench v1.62.00
...
[ERROR] HIP Error: invalid resource handle
```
Digging deeper into the logs, we find that the error is here:

```bash
AMD_LOG_LEVEL=7 TransferBench /opt/transferbench/rocm700/git_2d0ecaa/share/examples/example.cfg 
...
:3:hip_device_runtime.cpp   :702 : 178443593772 us: [pid:342566 tid: 0x7f5e22bff640]  hipSetDevice ( 0 ) 
:3:hip_device_runtime.cpp   :706 : 178443593800 us: [pid:342566 tid: 0x7f5e22bff640] hipSetDevice: Returned hipSuccess : 
:3:hip_module.cpp           :775 : 178443593849 us: [pid:342566 tid: 0x7f5e22bff640]  hipExtLaunchKernel ( 0x206f10, {1,4,1}, {256,1,1}, 0x7f5e22bf7390, 0, stream:0x53ded00, event:0x52d63f0, event:0x52d6520, 0 ) 
:3:hip_fatbin.cpp           :428 : 178443594118 us: [pid:342566 tid: 0x7f5e22bff640] Searching for code objects, HIP_FORCE_SPIRV_CODEOBJECT: 0
:1:hip_fatbin.cpp           :566 : 178443594125 us: [pid:342566 tid: 0x7f5e22bff640] No compatible code objects found for: gfx950:sramecc+:xnack-, value of HIP_FORCE_SPIRV_CODEOBJECT: 0
:3:hip_module.cpp           :784 : 178443594135 us: [pid:342566 tid: 0x7f5e22bff640] hipExtLaunchKernel: Returned hipErrorInvalidDeviceFunction :
```

A workaround is to force TransferBench to use the gfx942 code object, which is compatible with MI350X GPUs. This can be done by setting the `HSA_OVERRIDE_GFX_VERSION` environment variable to `9.4.2`.

```bash
HSA_OVERRIDE_GFX_VERSION=9.4.2 TransferBench /opt/transferbench/examples/example.cfg 
TransferBench v1.62.00
…
## Single GPU-executed Transfer between GPUs 0 and 1 using 4 CUs
Test 1:
 Executor: GPU 00 |   56.299 GB/s |    4.768 ms |    268435456 bytes | 56.309  GB/s (sum)
     Transfer 00  |   56.309 GB/s |    4.767 ms |    268435456 bytes | G0 -> G000:004 -> G1
 Aggregate (CPU)  |   55.015 GB/s |    4.879 ms |    268435456 bytes | Overhead: 0.111 ms
## Single DMA executed Transfer between GPUs 0 and 1
Test 2:
 Executor: DMA 00 |   59.334 GB/s |    4.524 ms |    268435456 bytes | 60.973  GB/s (sum)
     Transfer 00  |   60.973 GB/s |    4.403 ms |    268435456 bytes | G0 -> D000:001 -> G1
 Aggregate (CPU)  |   58.541 GB/s |    4.585 ms |    268435456 bytes | Overhead: 0.061 ms
## Copy 1Mb from GPU0 to GPU1 with 4 CUs, and 2Mb from GPU1 to GPU0 with 8 CUs
Test 3:
 Executor: GPU 00 |   36.885 GB/s |    0.028 ms |      1048576 bytes | 37.857  GB/s (sum)
     Transfer 00  |   37.857 GB/s |    0.028 ms |      1048576 bytes | G0 -> G000:004 -> G1
 Executor: GPU 01 |   45.471 GB/s |    0.046 ms |      2097152 bytes | 46.304  GB/s (sum)
     Transfer 01  |   46.304 GB/s |    0.045 ms |      2097152 bytes | G1 -> G001:008 -> G0
 Aggregate (CPU)  |   18.741 GB/s |    0.168 ms |      3145728 bytes | Overhead: 0.122 ms
## "Memset" by GPU 0 to GPU 0 memory
Test 4:
 Executor: GPU 00 | 1487.329 GB/s |    0.180 ms |    268435456 bytes | 1493.789 GB/s (sum)
     Transfer 00  | 1493.789 GB/s |    0.180 ms |    268435456 bytes | N -> G000:032 -> G0
 Aggregate (CPU)  |  698.995 GB/s |    0.384 ms |    268435456 bytes | Overhead: 0.204 ms
## "Read-only" by CPU 0
Test 5:
 Executor: CPU 00 |   37.356 GB/s |    7.186 ms |    268435456 bytes | 37.756  GB/s (sum)
     Transfer 00  |   37.756 GB/s |    7.110 ms |    268435456 bytes | C0 -> C000:004 -> N
 Aggregate (CPU)  |   36.803 GB/s |    7.294 ms |    268435456 bytes | Overhead: 0.108 ms
## Broadcast from GPU 0 to GPU 0 and GPU 1
Test 6:
 Executor: GPU 00 |   58.313 GB/s |    4.603 ms |    268435456 bytes | 58.327  GB/s (sum)
     Transfer 00  |   58.327 GB/s |    4.602 ms |    268435456 bytes | G0 -> G000:016 -> G0G1
 Aggregate (CPU)  |   56.768 GB/s |    4.729 ms |    268435456 bytes | Overhead: 0.125 ms
```

## 5.2 RCCL benchmarking results

### 5.2.1 RCCL qualification

Although RCCL is bundled with ROCm as a library, the RCCL tests are not. Build RCCL tests from source using the official documentation or by running the commands below in your terminal:

```bash
git clone https://github.com/ROCm/rccl-tests.git
cd rccl-tests
mkdir build && cd build || exit 1

cmake \
    -DCMAKE_INSTALL_PREFIX=/opt/rccl-tests/rocm700/git_aac5f2b \
    -DROCM_PATH=${ROCM_PATH} \
    -DCMAKE_BUILD_TYPE=Release \
    .. \
    2>&1 | tee log.cmake || exit 1

make -j32 2>&1 | tee log.make || exit 1
make install 2>&1 | tee log.make.install || exit 1
```

To evaluate the Allreduce operator using the RCCL tests benchmark, run the following command in your terminal:

```bash
all_reduce_perf -b 8 -e 8G -f 2 -g 8
```

The RCCL all-reduce test criteria is to exceed an in-place busbw metric of 304 GB/s at a message size of 8 GB.

Example output:

```bash
# nThread 1 nGpus 8 minBytes 8 maxBytes 8589934592 step: 2(factor) warmup iters: 5 iters: 20 agg iters: 1 validation: 1 graph: 0
#
rccl-tests: Version Unknown 
# Using devices
#  Rank  0 Group  0 Pid 657053 on smci350-zts-gtu-e14-05 device  0 [0000:75:00] AMD Instinct MI350X
#  Rank  1 Group  0 Pid 657053 on smci350-zts-gtu-e14-05 device  1 [0000:05:00] AMD Instinct MI350X
#  Rank  2 Group  0 Pid 657053 on smci350-zts-gtu-e14-05 device  2 [0000:65:00] AMD Instinct MI350X
#  Rank  3 Group  0 Pid 657053 on smci350-zts-gtu-e14-05 device  3 [0000:15:00] AMD Instinct MI350X
#  Rank  4 Group  0 Pid 657053 on smci350-zts-gtu-e14-05 device  4 [0000:f5:00] AMD Instinct MI350X
#  Rank  5 Group  0 Pid 657053 on smci350-zts-gtu-e14-05 device  5 [0000:85:00] AMD Instinct MI350X
#  Rank  6 Group  0 Pid 657053 on smci350-zts-gtu-e14-05 device  6 [0000:e5:00] AMD Instinct MI350X
#  Rank  7 Group  0 Pid 657053 on smci350-zts-gtu-e14-05 device  7 [0000:95:00] AMD Instinct MI350X
#
#                                                              out-of-place                       in-place          
#       size         count      type   redop    root     time   algbw   busbw #wrong     time   algbw   busbw #wrong
#        (B)    (elements)                               (us)  (GB/s)  (GB/s)            (us)  (GB/s)  (GB/s)       
           8             2     float     sum      -1    58.63    0.00    0.00      0    49.68    0.00    0.00      0
          16             4     float     sum      -1    51.42    0.00    0.00      0    51.15    0.00    0.00      0
          32             8     float     sum      -1    50.95    0.00    0.00      0    50.26    0.00    0.00      0
          64            16     float     sum      -1    50.20    0.00    0.00      0    56.04    0.00    0.00      0
         128            32     float     sum      -1    51.04    0.00    0.00      0    57.36    0.00    0.00      0
         256            64     float     sum      -1    43.78    0.01    0.01      0    43.42    0.01    0.01      0
         512           128     float     sum      -1    43.37    0.01    0.02      0    43.77    0.01    0.02      0
        1024           256     float     sum      -1    42.68    0.02    0.04      0    49.59    0.02    0.04      0
        2048           512     float     sum      -1    49.20    0.04    0.07      0    49.92    0.04    0.07      0
        4096          1024     float     sum      -1    50.88    0.08    0.14      0    49.81    0.08    0.14      0
        8192          2048     float     sum      -1    42.11    0.19    0.34      0    43.78    0.19    0.33      0
       16384          4096     float     sum      -1    49.84    0.33    0.58      0    50.24    0.33    0.57      0
       32768          8192     float     sum      -1    50.08    0.65    1.14      0    51.27    0.64    1.12      0
       65536         16384     float     sum      -1    50.03    1.31    2.29      0    43.56    1.50    2.63      0
      131072         32768     float     sum      -1    53.33    2.46    4.30      0    59.59    2.20    3.85      0
      262144         65536     float     sum      -1    59.53    4.40    7.71      0    53.49    4.90    8.58      0
      524288        131072     float     sum      -1    61.08    8.58   15.02      0    59.47    8.82   15.43      0
     1048576        262144     float     sum      -1    53.29   19.68   34.43      0    52.83   19.85   34.73      0
     2097152        524288     float     sum      -1    60.75   34.52   60.41      0    61.07   34.34   60.10      0
     4194304       1048576     float     sum      -1    57.41   73.06  127.85      0    56.88   73.75  129.05      0
     8388608       2097152     float     sum      -1    83.38  100.60  176.05      0    81.35  103.12  180.45      0
    16777216       4194304     float     sum      -1    140.4  119.50  209.13      0    141.8  118.32  207.06      0
    33554432       8388608     float     sum      -1    255.1  131.54  230.19      0    254.0  132.13  231.22      0
    67108864      16777216     float     sum      -1   1049.3   63.95  111.92      0    405.1  165.67  289.92      0
   134217728      33554432     float     sum      -1    694.2  193.34  338.35      0    695.7  192.94  337.64      0
   268435456      67108864     float     sum      -1   1947.9  137.81  241.16      0   1318.3  203.62  356.33      0
   536870912     134217728     float     sum      -1   2591.9  207.14  362.49      0   2589.3  207.34  362.84      0
  1073741824     268435456     float     sum      -1   5185.9  207.05  362.34      0   5184.9  207.09  362.41      0
  2147483648     536870912     float     sum      -1    15948  134.66  235.65      0    10279  208.92  365.60      0
  4294967296    1073741824     float     sum      -1    20503  209.48  366.58      0    20515  209.35  366.37      0
  8589934592    2147483648     float     sum      -1    41644  206.27  360.97      0    40903  210.01  367.51      0
# Errors with asterisks indicate errors that have exceeded the maximum threshold.
# Out of bounds values : 0 OK
# Avg bus bandwidth    : 111.827 
#
```

#### rccl-tests for with MPI support

If you want to run multi-node, then rccl-tests needs to be compiled with MPI support. Unfortunately, the Open MPI build that we have been using from the rocHPL build does not include header files. Therefore, we need to compile Open MPI manually.

The first step is to install the Slurm packages and header files. For Ubuntu 22.04, I am using the recipe that I have written on [Confluence](https://confluence.amd.com/pages/viewpage.action?pageId=1869117469)

```bash
sudo apt install slurm slurmd slurm-wlm slurmctld slurmdbd munge libmunge-dev
sudo apt install libslurm-dev
sudo apt install libpmix-dev libpmix-bin
```

The whole environment, including the Open MPI build, can be set up using the following script:

- hwloc
- XPMEM
- UCX
- UCC
- Open MPI

Is built with the script in `~mhilgema/app/openmpi/bin/build_all.sh`

Now `rccl-tests` can be compiled using our built Open MPI version:

```bash
cmake \
    -DCMAKE_INSTALL_PREFIX=/opt/rccl-tests/rocm700/openmpi/git_aac5f2b \
    -DROCM_PATH=${ROCM_PATH} \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_MPI=ON \
    .. 2>&1 | tee log.cmake || exit 1

make -j32 2>&1 | tee log.make || exit 1
make install 2>&1 | tee log.make.install || exit 1
```

The MPI enabled version of rccl-tests runs with one GPU per MPI rank and is launched by mpirun:

```bash
mpirun -np 8 all_reduce_perf -b 8 -e 8G -f 2 -g 1
# nThread 1 nGpus 1 minBytes 8 maxBytes 8589934592 step: 2(factor) warmup iters: 5 iters: 20 agg iters: 1 validation: 1 graph: 0
#
rccl-tests: Version Unknown 
# Using devices
#  Rank  0 Group  0 Pid 664991 on smci350-zts-gtu-e14-05 device  0 [0000:75:00] AMD Instinct MI350X
#  Rank  1 Group  0 Pid 664992 on smci350-zts-gtu-e14-05 device  1 [0000:05:00] AMD Instinct MI350X
#  Rank  2 Group  0 Pid 664993 on smci350-zts-gtu-e14-05 device  2 [0000:65:00] AMD Instinct MI350X
#  Rank  3 Group  0 Pid 664994 on smci350-zts-gtu-e14-05 device  3 [0000:15:00] AMD Instinct MI350X
#  Rank  4 Group  0 Pid 664995 on smci350-zts-gtu-e14-05 device  4 [0000:f5:00] AMD Instinct MI350X
#  Rank  5 Group  0 Pid 664996 on smci350-zts-gtu-e14-05 device  5 [0000:85:00] AMD Instinct MI350X
#  Rank  6 Group  0 Pid 664997 on smci350-zts-gtu-e14-05 device  6 [0000:e5:00] AMD Instinct MI350X
#  Rank  7 Group  0 Pid 664998 on smci350-zts-gtu-e14-05 device  7 [0000:95:00] AMD Instinct MI350X
#
#                                                              out-of-place                       in-place          
#       size         count      type   redop    root     time   algbw   busbw #wrong     time   algbw   busbw #wrong
#        (B)    (elements)                               (us)  (GB/s)  (GB/s)            (us)  (GB/s)  (GB/s)       
           8             2     float     sum      -1    18.96    0.00    0.00      0    16.95    0.00    0.00      0
          16             4     float     sum      -1    26.49    0.00    0.00      0    16.67    0.00    0.00      0
          32             8     float     sum      -1    17.66    0.00    0.00      0    17.72    0.00    0.00      0
          64            16     float     sum      -1    19.13    0.00    0.01      0    20.56    0.00    0.01      0
         128            32     float     sum      -1    23.81    0.01    0.01      0    24.20    0.01    0.01      0
         256            64     float     sum      -1    23.85    0.01    0.02      0    23.82    0.01    0.02      0
         512           128     float     sum      -1    23.91    0.02    0.04      0    23.83    0.02    0.04      0
        1024           256     float     sum      -1    13.22    0.08    0.14      0    13.69    0.07    0.13      0
        2048           512     float     sum      -1    13.15    0.16    0.27      0    13.03    0.16    0.28      0
        4096          1024     float     sum      -1    13.20    0.31    0.54      0    12.89    0.32    0.56      0
        8192          2048     float     sum      -1    13.36    0.61    1.07      0    13.12    0.62    1.09      0
       16384          4096     float     sum      -1    13.86    1.18    2.07      0    12.96    1.26    2.21      0
       32768          8192     float     sum      -1    13.37    2.45    4.29      0    12.99    2.52    4.41      0
       65536         16384     float     sum      -1    13.81    4.75    8.30      0    13.38    4.90    8.57      0
      131072         32768     float     sum      -1    14.00    9.36   16.38      0    13.95    9.40   16.45      0
      262144         65536     float     sum      -1    16.82   15.59   27.28      0    15.89   16.50   28.87      0
      524288        131072     float     sum      -1    23.58   22.23   38.91      0    21.90   23.94   41.90      0
     1048576        262144     float     sum      -1    25.76   40.70   71.23      0    24.97   41.99   73.48      0
     2097152        524288     float     sum      -1    33.00   63.55  111.21      0    32.29   64.96  113.67      0
     4194304       1048576     float     sum      -1    63.10   66.48  116.33      0    49.53   84.68  148.19      0
     8388608       2097152     float     sum      -1    79.73  105.21  184.12      0    79.17  105.96  185.43      0
    16777216       4194304     float     sum      -1    138.2  121.40  212.44      0    137.7  121.80  213.14      0
    33554432       8388608     float     sum      -1    263.6  127.29  222.76      0    251.2  133.57  233.75      0
    67108864      16777216     float     sum      -1   1488.9   45.07   78.87      0    414.6  161.85  283.24      0
   134217728      33554432     float     sum      -1    721.5  186.03  325.55      0    703.7  190.74  333.80      0
   268435456      67108864     float     sum      -1   1353.9  198.27  346.97      0   1342.3  199.98  349.97      0
   536870912     134217728     float     sum      -1   5318.5  100.94  176.65      0   3624.9  148.11  259.19      0
  1073741824     268435456     float     sum      -1    13592   79.00  138.25      0    17496   61.37  107.40      0
  2147483648     536870912     float     sum      -1    23196   92.58  162.02      0    25209   85.19  149.08      0
  4294967296    1073741824     float     sum      -1    29266  146.75  256.82      0    30396  141.30  247.27      0
  8589934592    2147483648     float     sum      -1    59342  144.75  253.32      0    51966  165.30  289.27      0
# Errors with asterisks indicate errors that have exceeded the maximum threshold.
# Out of bounds values : 0 OK
# Avg bus bandwidth    : 94.3116 
#
```

## 5.3.1 rocBLAS qualification

For detailed instructions, please visit https://rocm.docs.amd.com/projects/rocBLAS/en/develop/install/Linux_Install_Guide.html
For the scope of this document, we will be using rocblas-bench application/client. Rocblas-bench is not a part of prebuilt packages, hence we need to build the rocblas-bench.

### 5.3.1.1 Building and installing rocBLAS

rocBLAS can also be built from source to target tests and benchmarks only, which have a dependency on gtest and Python virtual envornments. On Ubuntu, install gtest by running the following command:

```bash
sudo apt install libgtest-dev rocblas python3-venv
```

Build the rocBLAS test and benchmark binaries from source by running the following commands in your terminal:

```bash
git clone https://github.com/ROCm/rocBLAS.git
cd rocBLAS
./install.sh --clients-only --library-path ${ROCM_PATH}
```

Copy the executables and YAML files:

```bash
sudo mkdir -p /opt/rocblas/rocm700/7.0.0/bin /opt/rocblas/rocm700/7.0.0/share
sudo cp $( find build/release/clients/staging -perm -o+x ) /opt/rocblas/rocm700/7.0.0/bin
sudo cp build/release/clients/staging/*.yaml /opt/rocblas/rocm700/7.0.0/share
```

--- DO NOT USE ---
This version does not natively support device kernels for MI350X, but we can add the offload target to the compiler:

```bash
sed -i 's/\(.*TARGET_LIST_ROCM_6.3.*\)gfx942;\(.*\)/\1gfx942;gfx950;\2/g;s/\(.*TARGET_LIST_ROCM_6.3.*\)gfx942:xnack+\(.*\)/\1gfx942:xnack+;gfx950:xnack+\2/g' CMakeLists.txt
```

Now start the build sequence:

```bash
cmake 
```
```
```


----- DO NOT USE ----
RocBLAS has been merged into the [rocm-libaries](https://github.com/ROCm/rocm-libraries) repository. rocm-libraries is a monorepo. This repository consolidates multiple ROCm-related libraries and shared components into a single repository to streamline development, CI, and integration. The first set of libraries focuses on components required for building PyTorch.

### 5.3.1.1 Building rocm-libaries

Clone the GitHub repo:

```bash
git clone https://github.com/ROCm/rocm-libraries.git
```

Load your ROCm environment and build rocBLAS:

```bash
module load rocm/7.0.0
cd rocm-libaries/projects/rocblas
```
----- DO NOT USE ----
