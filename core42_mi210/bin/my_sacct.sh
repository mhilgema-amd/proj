#!/bin/bash

#
# Pull Slurm usage stats from the last 7 days
#
# Author: Martin Hilgeman <mhilgema@amd.com>
# Date: Tue Jun 17 09:49:28 PM CEST 2025
#

sacct --allusers --allocations --starttime=now-7days --format=JobID,JobName,User,State,Elapsed,CPUTime,AllocNodes,Start,End -P
