#!/bin/bash
# Source: https://www.alibabacloud.com/blog/testing-io-performance-with-sysbench_594709

set -x # Print each command before execution

cd /nfs/workloads/slurm || exit 1
mkdir -p tmp
cd tmp || exit 1

sysbench fileio --file-total-size=8G --file-num=128 prepare
sysbench fileio --file-total-size=8G --file-num=128 --file-test-mode=seqrd --file-block-size=256K run
sysbench fileio --file-total-size=8G --file-num=128 --file-test-mode=seqwr --file-block-size=256K run
sysbench fileio cleanup