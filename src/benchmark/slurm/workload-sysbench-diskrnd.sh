#!/bin/bash
# Source: https://www.alibabacloud.com/blog/testing-io-performance-with-sysbench_594709
# Performs read and write test separately.

set -x # Print each command before execution

cd /nfs/workloads/slurm || exit 1
mkdir -p tmp
cd tmp || exit 1

sysbench fileio --file-total-size=1G --file-num=128 prepare
# --file-extra-flags=direct => the file reading and writing mode is changed to direct. FileIO is done directly from user space buffers. See O_DIRECT: https://www.man7.org/linux/man-pages/man2/open.2.html
sysbench fileio --file-total-size=1G --file-num=128 --file-test-mode=rndrd --file-block-size=256K --file-extra-flags=direct run
sysbench fileio --file-total-size=1G --file-num=128 --file-test-mode=rndwr --file-block-size=256K --file-extra-flags=direct run
sysbench fileio cleanup