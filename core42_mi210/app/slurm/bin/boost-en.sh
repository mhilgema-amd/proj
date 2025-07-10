#!/bin/bash

echo 1 > /sys/devices/system/cpu/cpufreq/boost
echo "CPU BOOST EN: `cat /sys/devices/system/cpu/cpufreq/boost`"


