#!/bin/bash

# Python venv with dependencies from requirements.txt should be active
# /bin/bash run-all-plot.sh

python plot-iperf3-bandwidth.py
python plot-netperf-latency-tcp.py

echo "Successfully created / updated plots"
