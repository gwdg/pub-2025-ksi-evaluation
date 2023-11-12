#!/bin/bash
set -x # Print each command before execution

cd /nfs/workloads/slurm || exit 1
mkdir -p tmp
cd tmp || exit 1

sysbench fileio --file-total-size=1G --file-num=4 prepare
sysbench fileio --file-total-size=1G --file-num=4 --file-test-mode=seqrd run
sysbench fileio --file-total-size=1G --file-num=4 --file-test-mode=seqwr run
sysbench fileio cleanup