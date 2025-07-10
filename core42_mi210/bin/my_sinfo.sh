#!/bin/bash
#
# sinfo with custom output
#
# Author: Martin Hilgeman
#
sinfo -o "%80E  %19H %N" | grep -v '^none' | sed 's/2025-/\;2025-/g;s/\(:[0-9][0-9]\)\ auh7/\1\;auh7/g'
