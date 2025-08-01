#!/bin/bash

# /bin/bash src2/benchmark/main.sh

set -e # fail and abort script if one command fails
set -o pipefail
set -x

# Set IP of the second node here and in the workload scripts
TEST_SERVER="10.239.3.66"
export TEST_SERVER

ONLY_PARSE="false"

# Function to parse benchmark outputs and format line for CSV files

function parseLogFile() {
  fileLog=${1:?} # parameter is mandatory

  datetime=$(date -Iseconds)
  # Extract benchmark metrics

  if [ "$BENCHMARK" == "iperf3-bandwidth" ]; then
    # awk to just grep json (starting from first { to last } )
    scoreBitsPerSec=$(awk '/^{/,/^}/' "$fileLog" | jq '.end.streams[0].sender.bits_per_second')
    # in Bits/s
    echo "$datetime;$DRIVER;$scoreBitsPerSec"

  elif [ "$BENCHMARK" == "netperf-latency-tcp" ]; then
    # Extract the line after the specified header
    header_line=$(grep -A 1 "Minimum Latency Microseconds,Maximum Latency Microseconds,Mean Latency Microseconds" "$fileLog" | tail -n 1)
    min_latency=$(echo "$header_line" | cut -d ',' -f 1)
    max_latency=$(echo "$header_line" | cut -d ',' -f 2)
    mean_latency=$(echo "$header_line" | cut -d ',' -f 3)
    stddev_latency=$(echo "$header_line" | cut -d ',' -f 4)
    # in Microseconds
    echo "$datetime;$DRIVER;$min_latency;$max_latency;$mean_latency;$stddev_latency"

  else
    echo "No benchmark found for '$BENCHMARK'" >&2
    exit 1
  fi
}

function initResultFile() {
  if [ "$BENCHMARK" == "iperf3-bandwidth" ]; then
    echo "date;driver;scoreBitsPerSec"
  elif [ "$BENCHMARK" == "netperf-latency-tcp" ]; then
    echo "date;driver;min_latency;max_latency;mean_latency;stddev_latency"
  else
    echo "No benchmark found for '$BENCHMARK'" >&2
    exit 1
  fi
}

function parseBenchmark() {
 for driver in "${drivers[@]}"; do
  fileResult="./data2/$BENCHMARK/$driver.csv"
  mkdir -p "./data2/$BENCHMARK/"
  export DRIVER="$driver"
  # Create and init result file
  initResultFile > "$fileResult" || (echo "Failed to init result file. No benchmark found for '$BENCHMARK'" >&2 && exit 1)
  for i in {01..10}; do
    fileLog="./logs2/$BENCHMARK/$driver/$i.txt"
    parseLogFile "$fileLog" >> "$fileResult" || (echo "Failed to parse log file. No benchmark found for '$BENCHMARK'" >&2 && exit 1)
  done
done
}


# Create dirs in case not already exist
mkdir -p logs2/
mkdir -p data2/

if [ "$ONLY_PARSE" == "false" ]; then

  # Empty dirs
  rm -rf logs2/*
  rm -rf data2/*

  mkdir -p logs2/netperf-latency-tcp/baseline/
  mkdir -p logs2/netperf-latency-tcp/podman-pasta/
  mkdir -p logs2/netperf-latency-tcp/nerdctl-slirp4netns/
  mkdir -p logs2/netperf-latency-tcp/nerdctl-bypass4netns/
  for i in {01..10}; do ../ksi/run-workload-original.sh src2/benchmark/netperf-latency-tcp.sh > logs2/netperf-latency-tcp/podman-pasta/$i.txt; done
  for i in {01..10}; do ../ksi/run-workload-no-liqo.sh src2/benchmark/netperf-latency-tcp.sh "$PWD" > logs2/netperf-latency-tcp/nerdctl-slirp4netns/$i.txt; done
  for i in {01..10}; do ../ksi/run-workload-no-liqo.sh src2/benchmark/netperf-latency-tcp.sh "$PWD" > logs2/netperf-latency-tcp/nerdctl-bypass4netns/$i.txt; done
  for i in {01..10}; do netperf -H $TEST_SERVER -p 16604 -l 30 -t TCP_RR -- -r 200 -o min_latency,max_latency,mean_latency,stddev_latency > logs2/netperf-latency-tcp/baseline/$i.txt; done

  mkdir -p logs2/iperf3-bandwidth/baseline/
  mkdir -p logs2/iperf3-bandwidth/podman-pasta/
  mkdir -p logs2/iperf3-bandwidth/nerdctl-bypass4netns/
  mkdir -p logs2/iperf3-bandwidth/nerdctl-slirp4netns/
  for i in {01..10}; do ../ksi/run-workload-original.sh src2/benchmark/iperf3-bandwidth.sh 2>&1 > logs2/iperf3-bandwidth/podman-pasta/$i.txt; done
  for i in {01..10}; do ../ksi/run-workload-no-liqo.sh src2/benchmark/iperf3-bandwidth.sh "$PWD" 2>&1 > logs2/iperf3-bandwidth/nerdctl-bypass4netns/$i.txt; done
  for i in {01..10}; do ../ksi/run-workload-no-liqo.sh src2/benchmark/iperf3-bandwidth.sh "$PWD" 2>&1 > logs2/iperf3-bandwidth/nerdctl-bypass4netns/$i.txt; done
  for i in {01..10}; do iperf3 --json -c $TEST_SERVER -p 5003 -i 1 -t 30 2>&1 > logs2/iperf3-bandwidth/baseline/$i.txt; done
fi

drivers=("podman-pasta" "nerdctl-bypass4netns" "nerdctl-slirp4netns" "baseline")

BENCHMARK="iperf3-bandwidth"
export BENCHMARK

parseBenchmark

BENCHMARK="netperf-latency-tcp"
export BENCHMARK

parseBenchmark
