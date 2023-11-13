#!/bin/bash
# Docs:
# - https://iperf.fr/iperf-doc.php#3doc
# - https://docs.nvidia.com/networking-ethernet-software/knowledge-base/Configuration-and-Usage/Monitoring/Throughput-Testing-and-Troubleshooting/

set -x # Print each command before execution

# verify hostname
hostname

# Runs iperf3 client. Expects iperf3 server running on other node $TEST_SERVER
iperf3 --json -c "$TEST_SERVER" -p 5003 -i 1 -t 30
