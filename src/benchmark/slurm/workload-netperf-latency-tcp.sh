#!/bin/bash
# Docs / Sources:
# - https://hewlettpackard.github.io/netperf/doc/netperf.html
# - https://cloud.google.com/blog/products/networking/using-netperf-and-ping-to-measure-network-latency?hl=en

set -x # Print each command before execution

# verify hostname
hostname

# Expects netperf server running on other node $NETPERF_SERVER.
# TCP request / response test with fixed packet size 200 byte for 30 sec
# -- is used as a separator, indicating that the options following it are specific to the underlying test (not netperf itself)
netperf -H $TEST_SERVER -p 16604 -l 30 -t TCP_RR -- -r 200 -o min_latency,max_latency,mean_latency,stddev_latency
