#!/bin/bash

# Function to parse benchmark outputs and format line for CSV files

function parseLogFile() {
  fileLog=${1:?} # parameter is mandatory

  datetime=$(date -Iseconds)
  # Extract benchmark metrics
  if [ "$BENCHMARK" == "sysbench-cpu" ]; then
    score=$(grep "events per second" "$fileLog" | awk '{print $4}')
    echo "$datetime;$PROJECT;$score"

  elif [ "$BENCHMARK" == "sysbench-diskrnd" ]; then
    scoreRead=$(grep "random read test" -A 25 "$fileLog" | grep "read, MiB/s" | awk '{print $3}')
    scoreWrite=$(grep "random write test" -A 25 "$fileLog" | grep "written, MiB/s" | awk '{print $3}')
    echo "$datetime;$PROJECT;$scoreRead;$scoreWrite"

  elif [ "$BENCHMARK" == "sysbench-diskseq" ]; then
    scoreRead=$(grep "sequential read test" -A 25 "$fileLog" | grep "read, MiB/s" | awk '{print $3}')
    scoreWrite=$(grep "sequential write (creation) test" -A 25 "$fileLog" | grep "written, MiB/s" | awk '{print $3}')
    echo "$datetime;$PROJECT;$scoreRead;$scoreWrite"

  elif [ "$BENCHMARK" == "fio-diskseq" ]; then
    # Source: https://andypeace.com/fio_minimal.html
    scoreRead=$(grep "kube-fio-read;" "$fileLog" | cut -d ';' -f 7)
    scoreWrite=$(grep "kube-fio-write;" "$fileLog" | cut -d ';' -f 48)
    # in KiB/s
    echo "$datetime;$PROJECT;$scoreRead;$scoreWrite"

  elif [ "$BENCHMARK" == "bonnie-diskseq" ]; then
    # last line always csv
    scoreRead=$(grep "kube-bonnie-result" "$fileLog" | cut -d ',' -f 18) # In Bonnie++: Sequential Input Block K/sec
    scoreWrite=$(grep "kube-bonnie-result" "$fileLog" | cut -d ',' -f 12) # In Bonnie++: Sequential Output Block in K/sec
    echo "$datetime;$PROJECT;$scoreRead;$scoreWrite"

  elif [ "$BENCHMARK" == "stream-memory" ]; then
    scoreCopy=$(grep "STREAM version" -A 40 "$fileLog" | grep "Copy" | awk '{print $2}')
    scoreScale=$(grep "STREAM version" -A 40 "$fileLog" | grep "Scale" | awk '{print $2}')
    scoreAdd=$(grep "STREAM version" -A 40 "$fileLog" | grep "Add" | awk '{print $2}')
    scoreTriad=$(grep "STREAM version" -A 40 "$fileLog" | grep "Triad" | awk '{print $2}')
    # in MB/s
    echo "$datetime;$PROJECT;$scoreCopy;$scoreScale;$scoreAdd;$scoreTriad"

  elif [ "$BENCHMARK" == "iperf3-bandwidth" ]; then
    # awk to just grep json (starting from first { to last } )
    scoreBitsPerSec=$(awk '/^{/,/^}/' "$fileLog" | jq '.end.streams[0].sender.bits_per_second')
    # in Bits/s
    echo "$datetime;$PROJECT;$scoreBitsPerSec"

  elif [ "$BENCHMARK" == "netperf-latency-tcp" ]; then
    # Extract the line after the specified header
    header_line=$(grep -A 1 "Minimum Latency Microseconds,Maximum Latency Microseconds,Mean Latency Microseconds" "$fileLog" | tail -n 1)
    min_latency=$(echo "$header_line" | cut -d ',' -f 1)
    max_latency=$(echo "$header_line" | cut -d ',' -f 2)
    mean_latency=$(echo "$header_line" | cut -d ',' -f 3)
    stddev_latency=$(echo "$header_line" | cut -d ',' -f 4)
    # in Microseconds
    echo "$datetime;$PROJECT;$min_latency;$max_latency;$mean_latency;$stddev_latency"

  elif [ "$BENCHMARK" == "startup-time" ]; then
    workloadStartMillis=$(grep "workload-start-millis" "$fileLog" | tail -n 1 | awk '{print $2}')
    delayMillis=$((workloadStartMillis - START_MILLIS))
    echo "$datetime;$PROJECT;$delayMillis"

  else
    echo "No benchmark found for '$BENCHMARK'" >&2
    exit 1
  fi
}

function initResultFile() {
  if [ "$BENCHMARK" == "sysbench-cpu" ]; then
    echo "date;project;score"
  elif [ "$BENCHMARK" == "sysbench-diskrnd" ]; then
    echo "date;project;readthroughput;writethroughput"
  elif [ "$BENCHMARK" == "sysbench-diskseq" ]; then
    echo "date;project;readthroughput;writethroughput"
  elif [ "$BENCHMARK" == "fio-diskrnd" ]; then
    echo "date;project;readthroughput;writethroughput"
  elif [ "$BENCHMARK" == "fio-diskseq" ]; then
    echo "date;project;readthroughput;writethroughput"
  elif [ "$BENCHMARK" == "bonnie-diskseq" ]; then
    echo "date;project;readthroughput;writethroughput"
  elif [ "$BENCHMARK" == "stream-memory" ]; then
    echo "date;project;copy;scale;add;triad"
  elif [ "$BENCHMARK" == "iperf3-bandwidth" ]; then
    echo "date;project;scoreBitsPerSec"
  elif [ "$BENCHMARK" == "netperf-latency-tcp" ]; then
    echo "date;project;min_latency;max_latency;mean_latency;stddev_latency"
  elif [ "$BENCHMARK" == "startup-time" ]; then
    echo "date;project;millis"
  else
    echo "No benchmark found for '$BENCHMARK'" >&2
    exit 1
  fi
}