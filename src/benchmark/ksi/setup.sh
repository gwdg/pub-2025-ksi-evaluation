#!/bin/bash
# Runs setup - e.g. ensures certain prerequisites each benchmark execution (not each iteration)
# Script should be execute on Slurm cluster

set -x # Print each command before execution
set -e # fail and abort script if one command fails
set -o pipefail

cd /nfs/workloads || exit 1

# Setup integration project
# Clone KSI repository
if [ ! -d "kind-slurm-integration" ]; then
  echo "kind-slurm-integration directory does not exist. Cloning repository first..."
  git clone https://github.com/soerenmetje/kind-slurm-integration.git
else
  echo "kind-slurm-integration directory already exist."
fi

cd "kind-slurm-integration" || exit 1
git pull

mkdir -p /nfs/workloads/kind-slurm-integration/benchmark/ksi