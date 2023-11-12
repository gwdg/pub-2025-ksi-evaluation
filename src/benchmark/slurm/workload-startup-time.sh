#!/bin/bash
set -x # Print each command before execution

# number of milliseconds since the epoch. Source :https://serverfault.com/a/151112
echo "workload-start-millis $(date +%s%N | cut -b1-13)"