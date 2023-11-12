#!/bin/bash
set -x # Print each command before execution

cd /nfs/workloads/slurm || exit 1
mkdir -p tmp
cd tmp || exit 1

sysbench fileio --file-total-size=1G --file-num=128 prepare
sysbench fileio --file-total-size=1G --file-num=128 --file-test-mode=rndrd --max-requests=0 run
sysbench fileio --file-total-size=1G --file-num=128 --file-test-mode=rndwr --max-requests=0 run
sysbench fileio cleanup