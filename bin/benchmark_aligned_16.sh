PERIOD=20123

perf record -e arm_spe_0/load_filter=1,jitter=1,period=$PERIOD/ ./aligned-16-inst-loop
#perf record -e arm_spe_0/jitter=1,period=$PERIOD/ ./aligned-16-inst-loop
perf annotate
