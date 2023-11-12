#!/bin/bash
# Runs setup - e.g. ensures certain prerequisites each benchmark execution (not each iteration)
# Script should be execute on Slurm cluster

set -x # Print each command before execution
set -e # fail and abort script if one command fails
set -o pipefail

cd /nfs/workloads || exit 1

mkdir -p /nfs/workloads/slurm/benchmark

# Prerequisites for Stream benchmark
cd /nfs/workloads/slurm

if [ ! -d "docker-stream" ]; then
  echo "docker-stream directory does not exist. Cloning repository first..."
  git clone https://github.com/soerenmetje/docker-stream.git
else
  echo "docker-stream directory already exist."
fi

cd "docker-stream" || exit 1
git pull
