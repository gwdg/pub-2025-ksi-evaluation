#!/bin/bash

set -e # fail and abort script if one command fails
set -o pipefail

python3 plot-fio-diskrnd.py && echo "Successfully created / updated plot"
python3 plot-fio-diskseq.py && echo "Successfully created / updated plot"
python3 plot-iperf3-bandwidth.py && echo "Successfully created / updated plot"
python3 plot-netperf-latency-tcp.py && echo "Successfully created / updated plot"
python3 plot-startup-time.py && echo "Successfully created / updated plot"
python3 plot-stream-memory.py && echo "Successfully created / updated plot"
python3 plot-sysbench-cpu.py && echo "Successfully created / updated plot"
python3 plot-sysbench-diskrnd.py && echo "Successfully created / updated plot"
python3 plot-sysbench-diskseq.py && echo "Successfully created / updated plot"
