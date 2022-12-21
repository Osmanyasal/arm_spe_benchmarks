PERIOD=100003

perf record -e arm_spe_0/jitter=1,period=$PERIOD/ ./5-ld-5-st
perf annotate
