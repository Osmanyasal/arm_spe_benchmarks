#!/bin/bash

PERIOD=2048
ITER=100
JITTER=1
HEAD=5
BINARY=bin/5-ld-5-st-1-mil
STORE_FILTER=0
LOAD_FILTER=0
BRANCH_FILTER=0

while getopts "p:j:b:i:h:s:l:f:" flag
do
    case "${flag}" in
        p) PERIOD=${OPTARG};;
        j) JITTER=${OPTARG};;
        b) BINARY=${OPTARG};;
        h) HEAD=${OPTARG};;
        i) ITER=${OPTARG};;
        s) STORE_FILTER=${OPTARG};;
        l) LOAD_FILTER=${OPTARG};;
        f) BRANCH_FILTER=${OPTARG};;
    esac
done

make all

BASE=$(basename ${BINARY})
PERF_COMMAND='sudo /home/barbara/arm_spe/linux/tools/perf/perf'
PERF_FILE=data/${BASE}.${PERIOD}.j${JITTER}.latency.perf.data
LOG_FILE=logs/${BASE}.${PERIOD}.j${JITTER}.latency.perf.log
RESULT_FILE=results/${BASE}.${PERIOD}.j${JITTER}.s${STORE_FILTER}.l${LOAD_FILTER}.f${BRANCH_FILTER}.latency.csv

# dump disassembly of the executable
objdump -D ${BINARY} > logs/${BASE}.ds

echo "# period=${PERIOD}, jitter=${JITTER}, iter=${ITER}, head=${HEAD}" > ${RESULT_FILE}
echo "# store_filter=${STORE_FILTER}, load_filter=${LOAD_FILTER}, branch_filter=${BRANCH_FILTER}" >> ${RESULT_FILE}
echo "VA,AVG_LAT,SAMPLES" >> ${RESULT_FILE}


for (( i=0; i<${ITER}; i++ ))
    do
    # run perf command
    ${PERF_COMMAND} record -e arm_spe_0/jitter=${JITTER},period=${PERIOD},ts_enable=0,store_filter=${STORE_FILTER},load_filter=${LOAD_FILTER},branch_filter=${BRANCH_FILTER}/ -o ${PERF_FILE} -- ${BINARY}
    # get raw data
    ${PERF_COMMAND} report -D -i ${PERF_FILE} > ${LOG_FILE}
    # count samples by PC and report associated average total latency
    grep -E 'PC 0x.* ' -A 5  ${LOG_FILE} | grep -o -E '0x.*$|LAT [0-9]* TOT' | sed ':begin;$!N;s/ el[0-3] ns=[0-1]\nLAT /,/' \
    | tr -d ' TOT' | awk -F ',' -v OFS=',' '{seen[$1]+=$2; count[$1]++} END{for (x in seen)print x, seen[x]/count[x], count[x]}'\
    | sort -t ',' | head -${HEAD} >> ${RESULT_FILE}
    done


#awk -F ',' '{print $1}' logs/${BASE}.${PERIOD}.latency.temp.log | sort | uniq -c | sort -nr > logs/${BASE}.${PERIOD}.latency.unique.log