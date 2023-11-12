#!/bin/bash
# Infos about STREAM: https://stackoverflow.com/questions/56086993/what-does-stream-memory-bandwidth-benchmark-really-measure

set -x # Print each command before execution

cd /nfs/workloads/slurm/docker-stream || exit 1

export ARRAYSIZE=100000000
export THREADS=56

/bin/sh stream.sh