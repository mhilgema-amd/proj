#!/bin/bash
#
# This script converts a list of hostnames in Slurm/pdsh format
# to one host per line
#
# Author: Martin Hilgeman <martin.hilgeman@amd.com>
# Date: Wed May 14 15:13:58 +04 2025
#

if [ $# -ne 1 ]; then
    echo "Usage: $0 '<range>'"
else
    input="$1"
fi

hostnames=()
current_prefix=""
in_brackets=0
current_item=""
debug=0

for ((i = 0; i < ${#input}; i++)); do
    char="${input:$i:1}"
    if [ ${debug} -gt 0 ]; then
        echo "Processing char: '$char', in_brackets: $in_brackets, current_prefix: '$current_prefix', current_item: '$current_item'"
    fi

    if [[ "$char" == "[" ]]; then
        in_brackets=1
        current_item=""
    elif [[ "$char" == "]" ]]; then
        in_brackets=0
        IFS=',' read -ra parts <<<"$current_item"
        if [ ${debug} -gt 0 ]; then
            echo "Found closing bracket, processing parts: '${parts[@]}'"
        fi
        for part in "${parts[@]}"; do
            if [[ "$part" =~ - ]]; then
                start="$((10#$(echo "$part" | cut -d'-' -f1)))"
                end="$((10#$(echo "$part" | cut -d'-' -f2)))"
                if [ ${debug} -gt 0 ]; then
                    echo "  Range: $start - $end"
                fi
                for ((j = start; j <= end; j++)); do
                    hostname="${current_prefix}$(printf "%03d" "$j")"
                    hostnames+=("$hostname")
                    if [ ${debug} -gt 0 ]; then
                        echo "    Adding hostname: '$hostname'"
                    fi
                done
            else
                hostname="${current_prefix}$(printf "%03d" "$((10#$part))")"
                hostnames+=("$hostname")
                if [ ${debug} -gt 0 ]; then
                    echo "    Adding hostname: '$hostname'"
                fi
            fi
        done
        current_prefix=""
        current_item=""
    elif [[ "$char" == "," ]]; then
        if [[ "$in_brackets" -eq 0 ]] && [[ "$current_prefix" != "" ]]; then
            hostnames+=("$current_prefix")
            if [ ${debug} -gt 0 ]; then
                echo "    Adding simple hostname: '$current_prefix'"
            fi
            current_prefix=""
            current_item=""
        elif [[ "$in_brackets" -eq 1 ]]; then
            # Process the current item before the comma
            if [[ "$current_item" =~ - ]]; then
                start="$((10#$(echo "$current_item" | cut -d'-' -f1)))"
                end="$((10#$(echo "$current_item" | cut -d'-' -f2)))"
                if [ ${debug} -gt 0 ]; then
                    echo "  Range (comma): $start - $end"
                fi
                for ((j = start; j <= end; j++)); do
                    hostname="${current_prefix}$(printf "%03d" "$j")"
                    hostnames+=("$hostname")
                    if [ ${debug} -gt 0 ]; then
                        echo "    Adding hostname (comma): '$hostname'"
                    fi
                done
            elif [[ "$current_item" != "" ]]; then
                hostname="${current_prefix}$(printf "%03d" "$((10#$current_item))")"
                hostnames+=("$hostname")
                if [ ${debug} -gt 0 ]; then
                    echo "    Adding hostname (comma): '$hostname'"
                fi
            fi
            current_item=""
        fi
    elif [[ "$char" == "-" ]] && [[ "$in_brackets" -eq 1 ]]; then
        current_item+="$char"
    elif [[ "$char" =~ [0-9] ]] && [[ "$in_brackets" -eq 1 ]]; then
        current_item+="$char"
    else
        current_prefix+="$char"
    fi
done

# Add the last prefix if it's a simple hostname
if [[ "$in_brackets" -eq 0 ]] && [[ "$current_prefix" != "" ]]; then
    hostnames+=("$current_prefix")
    if [ ${debug} -gt 0 ]; then
        echo "    Adding final simple hostname: '$current_prefix'"
    fi
fi

# Output the collected hostnames
if [ ${debug} -gt 0 ]; then
    echo "Final hostnames array: '${hostnames[@]}'"
fi
for hostname in "${hostnames[@]}"; do
    echo "$hostname"
done
