#!/bin/bash
# Example Frontier GPU wrapper script contributed by Wael Elwasif
#
# ChangeLog
#  v1.2: switch to HIP_VISIBLE_DEVICES and not set ROCR_VISIBLE_DEVICES
#  v1.1: avoid setting HIP_VISIBLE_DEVICES
#  v1.0: initial version
#

VERSION=1.2
SCRIPT="gpuwrapper.sh"

VERBOSE=0
SHOWHELP=0
OPTIND=1

usage() {
    echo "Version $VERSION"
    echo "Usage: $SCRIPT [-h] [-v] command-line"
    echo "  The 'command-line' is target command and arguments to execute"
    echo "  e.g.,   $SCRIPT  ./a.out arg1"
    echo ""
    echo "     -v      Verbose script output"
    echo "     -h      Print this help info"
}

while getopts hv opt ; do
    case "$opt" in
        v) VERBOSE=1;;              # '-v' Verbose output
        h) SHOWHELP=1;;             # '-h' Print help/usage info
    esac
done

shift $(($OPTIND - 1))
if [ "$1" = '--' ]; then
    shift
fi

function map_gpu() {
    local c0=$1
    local c1=$2
    local c2=$3
    local c3=$4
    local gpu=$5
    for c in $(
        seq $c0 $c1
        seq $c2 $c3
    ); do
        gpumap[$c]=$gpu
    done
}

#NUMA 0:
map_gpu 0 7 64 71 4
map_gpu 8 15 72 79 5
#NUMA 1:
map_gpu 16 23 80 87 2
map_gpu 24 31 88 95 3
#NUMA 2:
map_gpu 32 39 96 103 6
map_gpu 40 47 104 111 7
#NUMA 3:
map_gpu 48 55 112 119 0
map_gpu 56 63 120 127 1


if [ 1 == $SHOWHELP ] ; then
    usage
    exit 0
fi


corelist=$(taskset -c -p $$ | awk '{print $NF}')
readarray -d , -t strarr <<<$(echo "$corelist")

unset ROCR_VISIBLE_DEVICES

length=${#strarr[*]}
for ((n = 0; n < $length; n++)); do
    entry="${strarr[$n]/$'\n'/}"
    readarray -d - -t cpus <<<"$entry"
    ntokens=${#cpus[*]}
    if [ $ntokens -eq 2 ]; then
        first=${cpus[0]}
        last=${cpus[1]/$'\n'/}
        for c in $(seq $first $last); do
            visible[${gpumap[$c]}]=1
        done
    else
        visible[${gpumap[$entry]}]=1
    fi
done

devices="${!visible[@]}"
#export ROCR_VISIBLE_DEVICES=${devices// /,}
export HIP_VISIBLE_DEVICES=${devices// /,}

####
# TJN: I found that setting HIP_VISIBLE_DEVICES (and ROCR_VISIBLE_DEVICES)
#      sometimes resulted in errors about hipGetDeviceCount() failing,
#        "...osu_util_mpi.c:2815] ROCM call 'hipGetDeviceCount(&dev_count)' failed with 100: no ROCm-capable device is detected"
#
#export HIP_VISIBLE_DEVICES=$ROCR_VISIBLE_DEVICES
####

if [ 1 == $VERBOSE ]; then
    cpustr=$(taskset -c -p $$)
    #echo "$(hostname) $cpustr using ROCR_VISIBLE_DEVICES=${ROCR_VISIBLE_DEVICES}"
    echo "$(hostname) $cpustr using HIP_VISIBLE_DEVICES=${HIP_VISIBLE_DEVICES}"
fi

exec "$@"
