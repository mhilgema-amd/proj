#!/usr/bin/bash
#
# Author:      Martin Hilgeman <martin.hilgeman@amd.com>
# Date:        07/11/2025 08:59:49
# Description: A script to calculate the optimal P, Q and N value
# for HPL
#

#
# Aliases and functions
#
function USAGE() {
    echo "Usage: $0 -m <memory per node in GB> -b <block size> -f <percentage of memory> -n <numer of nodes> -p <PPN per node>"
    exit 1
}

if [ $# -lt 5 ]; then USAGE; fi

#
# Process command line arguments
#
ARGV=$#
APP=$(basename $0)
OPTIND=1
while getopts ":m:b:f:n:p:" args; do
    case "$args" in
    m)
        MEM=$OPTARG
        ;;
    b)
        NB=$OPTARG
        ;;
    f)
        FRACTION=$OPTARG
        ;;
    n)
        NNODES=$OPTARG
        ;;
    p)
        PPN=$OPTARG
        ;;
    \?)
        echo "$APP: invalid option: -$OPTARG" >&2
        USAGE
        ;;
    esac
done
shift $((OPTIND - 1))

header_pq="\n%5s %5s\n"
values_pq=" %5d %5d\n"

header_n="\n %7s %6s\n"
values_n=" % 4d %s %8d\n"

NPES=$((${NNODES} * ${PPN}))

printf "$header_pq" "P" "Q"
printf "   %s   %s\n" "===" "==="
for p in $(seq 1 $NPES); do
    if [ $(($NPES % $p)) -eq 0 ]; then
        q=$((NPES / $p))
        if [ $q -ge $p ]; then
            printf "$values_pq" "$p" "$q"
        fi
    fi
done
echo -ne "\n"

printf "$header_n" "NB=$NB" "N"
printf "  %s   %s\n" "======" "======"
n_aggr=$(echo "${MEM} * 1024^3 *  ${NNODES}" | bc)
N=$(echo "scale=0; sqrt((${n_aggr} / 8) * ${FRACTION} ) / 1" | bc)

while [ $((${N} % ${NB})) -ne 0 ]; do
    N=$(($N + 1))
done

printf "${values_n}" "${MEM}" "GB" "$N"
echo -ne "\n"
