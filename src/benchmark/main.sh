#!/bin/bash
# Script to run a variety of benchmarks on several projects
# Run Script on local computer/laptop from project root.
# Parameters:
# - project
# - benchmark
#
# /bin/bash src/benchmark/main.sh ksi sysbench-cpu


set -e # fail and abort script if one command fails
set -o pipefail


if [ -z "$1" ]; then
    echo "Missing argument: project is not specified. Pass one of the following values [ksi hpk bridge-operator slurm]" >&2
    exit 1
fi

# TODO add more benchmark values
if [ -z "$2" ]; then
    echo "Missing argument: benchmark is not specified. Pass one of the following values [sysbench-cpu ]" >&2
    exit 1
fi

export PROJECT=$1
export BENCHMARK=$2

export SLURM_HOST="10.10.41.10"
export SLURM_USER="smetje"


# Find out and returns the next benchmark number. This can be used for the next result file.
# Expects a directory to result files as a parameter.
# E.g. if following files already exit 000.csv 001.csv
# the next benchmark number is 2
function getNextBenchmarkNumber() {
  local resultDir=${1:?} # parameter is mandatory

  # Source: https://stackoverflow.com/a/76573714/14355362
  local entries=("$resultDir"/*)
  [[ ${entries[0]} == "$resultDir/*" ]] && unset entries[0]

  local num
  if [ ${#entries[@]} != 0 ]; then
    num=$(basename "${entries[-1]}" | sed -e s/[^0-9]//g)
    num=$((num+1))
  else
    # No result files yet
    num=0
  fi
  # Return
  echo $num
}

dirResult="data/$BENCHMARK/$PROJECT"
mkdir -p "$dirResult"

benchmarkNumber=$(getNextBenchmarkNumber "$dirResult")
# Source: https://stackoverflow.com/a/18460742/14355362
fileResult=$(printf "$dirResult/%03d.csv" $benchmarkNumber)
echo "Result file: $fileResult"

dirLogs=$(printf "./logs/$BENCHMARK/$PROJECT/%03d/" $benchmarkNumber)
mkdir -p "$dirLogs"

if [ "$PROJECT" == "ksi" ]; then

  # Run setup script on Slurm cluster using SSH
  # Source: https://stackoverflow.com/a/76544706/14355362
  cat src/benchmark/ksi/setup.sh | ssh -i "$HOME/.ssh/id_rsa" $SLURM_USER@$SLURM_HOST bash -s

  # Copy the benchmark scripts using scp
  scp -r -i "$HOME/.ssh/id_rsa" src/benchmark/* $SLURM_USER@$SLURM_HOST:/nfs/workloads/kind-slurm-integration/benchmark

  # Run benchmark script on Slurm cluster using SSH
  cat src/benchmark/ksi/bench.sh | ssh -i "$HOME/.ssh/id_rsa" $SLURM_USER@$SLURM_HOST bash -s -- "$BENCHMARK"


  # Copy benchmark result files from Slurm cluster back to laptop
  scp -i "$HOME/.ssh/id_rsa" $SLURM_USER@$SLURM_HOST:/nfs/workloads/kind-slurm-integration/data/temp.csv "$fileResult"

  # Copy log files from Slurm cluster back to laptop
  scp -r -i "$HOME/.ssh/id_rsa" $SLURM_USER@$SLURM_HOST:/nfs/workloads/kind-slurm-integration/logs/* "$dirLogs"

elif [ "$PROJECT" == "slurm" ]; then
  # Run setup script on Slurm cluster using SSH
  # Source: https://stackoverflow.com/a/76544706/14355362
  cat src/benchmark/slurm/setup.sh | ssh -i "$HOME/.ssh/id_rsa" $SLURM_USER@$SLURM_HOST bash -s

  # Copy the benchmark scripts using scp
  scp -r -i "$HOME/.ssh/id_rsa" src/benchmark/* $SLURM_USER@$SLURM_HOST:/nfs/workloads/slurm/benchmark

  # Run benchmark script on Slurm cluster using SSH
  cat src/benchmark/slurm/bench.sh | ssh -i "$HOME/.ssh/id_rsa" $SLURM_USER@$SLURM_HOST bash -s -- "$BENCHMARK"


  # Copy benchmark result files from Slurm cluster back to laptop
  scp -i "$HOME/.ssh/id_rsa" $SLURM_USER@$SLURM_HOST:/nfs/workloads/slurm/data/temp.csv "$fileResult"

  # Copy log files from Slurm cluster back to laptop
  scp -r -i "$HOME/.ssh/id_rsa" $SLURM_USER@$SLURM_HOST:/nfs/workloads/slurm/logs/* "$dirLogs"
else
  echo "No project found for '$PROJECT'" >&2
  exit 1
fi

# TODO Run plotting python script dep. on Benchmark

