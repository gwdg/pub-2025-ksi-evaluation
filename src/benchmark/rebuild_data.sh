#!/bin/bash
# In case the parsing failed during execution of main.sh,
# this script can be used to build the csv file from the stored log files.
#
# Run example: /bin/bash src/benchmark/rebuild_data.sh slurm fio-diskseq 000

set -e # fail and abort script if one command fails
set -o pipefail


if [ -z "$1" ]; then
    echo "Missing argument: project is not specified. Pass one of the following values [ksi hpk bridge-operator slurm]" >&2
    exit 1
fi

if [ -z "$2" ]; then
    echo "Missing argument: benchmark is not specified. " >&2
    exit 1
fi

if [ -z "$3" ]; then
    echo "Missing argument: Run not specified - e.g. 003" >&2
    exit 1
fi

export PROJECT=$1
export BENCHMARK=$2
export RUN=$3 # e.g. 003
export ITERATIONS=10
fileResult="./data/$BENCHMARK/$PROJECT/${RUN}_1.csv"


# Load parse and init functions
source ./src/benchmark/common/parse.sh

initResultFile > "$fileResult" || (echo "Failed to init result file. No benchmark found for '$BENCHMARK'" >&2 && exit 1)

for (( i=0; i<ITERATIONS; i++ )); do
  echo "Parsing logfile for interation $i / $ITERATIONS ..."

  fileLog="./logs/$BENCHMARK/$PROJECT/$RUN/$(printf "log%03d.txt" $i)"

  parseLogFile "$fileLog" >> "$fileResult" || (echo "Failed to parse log file. No benchmark found for '$BENCHMARK'" >&2 && exit 1)
done