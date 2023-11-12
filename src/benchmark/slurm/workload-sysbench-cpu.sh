#!/bin/bash
set -x # Print each command before execution

sysbench cpu --threads=56 --cpu-max-prime=20000 run