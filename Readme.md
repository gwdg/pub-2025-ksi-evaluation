# Kubernetes Slurm Evaluation

This repository implements an approach to evaluate projects that integrate Kubernetes and Slurm.
This project is part of my master’s thesis at the [Georg August University of Göttingen](https://www.uni-goettingen.de). The goal of the thesis is to investigate approaches to run Kubernetes workloads in a Slurm cluster.
In this repository, the following projects are subject of our evaluation:
- [IBM/Bridge-Operator](https://github.com/IBM/Bridge-Operator)
- [CARV-ICS-FORTH/HPK](https://github.com/CARV-ICS-FORTH/HPK)
- [soerenmetje/KSI](https://github.com/soerenmetje/kind-slurm-integration)
- Slurm (without any Kubernetes integration - serves as a reference point / base line)

> We are aware of further projects such as [Sylabs/WLM-Operator](https://github.com/sylabs/wlm-operator), [SchedMD/slurm-k8s-bridge](https://gitlab.com/SchedMD/training/slurm-k8s-bridge), and [kalenpeterson/kube-slurm](https://github.com/kalenpeterson/kube-slurm). 
> However, these projects are either strongly deprecated and did not pass our minimal functional test 
> or aim at a different goal. Therefore, these projects are not included.

In our evaluation we used the following benchmark tools to evaluate certain metrics:

| Metric                 | Benchmarks                                             |
|------------------------|--------------------------------------------------------|
| CPU performance        | Sysbench CPU                                           |
| Memory throughput      | [Stream](https://github.com/soerenmetje/docker-stream) |
| Disk throughput        | Sysbench FileIO (rnd / seq)                            |
| Network throughput     | Iperf3                                                 |
| Network latency        | Netperf                                                |
| Workload start up time | our own approach                                       |

> Unfortunately, the tool Nuttcp seems to have no package for CentOS Stream 9. 
> Therefore, instead of compiling Nuttcp on our own, we simply use Iperf3 that serves the same functionality.
 

## Content
- Shell scripts in `src/benchmark/`:
  - to perform benchmarks on each project
  - to write benchmark results into `.csv` files
- Python scripts in `src/plot/`
  - to read the result files
  - to create plots
- CSV result files in `data/`
- Log files in `logs/`
- Plot images in `plots/`

## Prerequisites
To perform the evaluation, a certain prerequisites have to be ensured:
- Slurm cluster up and running.
- Local machine (e.g. laptop) runs a Linux distribution. We tested this setup using Ubuntu 22.04.
- Local machine (e.g. laptop) can log in on the Slurm master node using SSH and the SSH key `.ssh/id_rsa`.
- Local machine has `bash`, `ssh`, and `python3` installed as well as the python packages defined in [requirements.txt](requirements.txt).
- All prerequisites of all projects (KSI, HPK, Bridge-Operator) are ensured.
- For Slurm and Bridge-Operator benchmarks, the benchmark tools has to be installed on the cluster nodes. KSI and HPK use container images and therefore do not rely on installed software.

## Getting Started
This repository contains a script [main.sh](src/benchmark/main.sh). This script is designed to be executed locally, e.g., on a laptop. It 
- connects to the Slurm cluster (and Kubernetes cluster if needed)
- runs benchmarks
- copies the result file (`.csv`) as well as log files from cluster back to the local machine

Following command is an example for evaluating the `ksi` project using the `stream-memory` benchmark:
```shell
# /bin/bash src/benchmark/main.sh <project> <benchmark>
/bin/bash src/benchmark/main.sh ksi stream-memory
```
After execution, the result file can be obtained in `data/` and the log files in `logs/`.

### Parameters
Available parameters - the project and the benchmark - can be determined by the directory and file names.
The directory names in `src/benchmark/` are the available projects:
- `ksi`
- `hpk`
- `bridge-operator`
- `slurm`

The available benchmarks can be determined by the file names `workload-*.sh` inside the project directories:
- `sysbench-cpu`
- `sysbench-diskrnd`
- `sysbench-diskseq`
- `stream-memory`
- `netperf-latency-tcp`
- `iperf3-bandwidth`
- `startup-time`


## Notes
- For testing we disabled writing caching as described here: https://stackoverflow.com/questions/20215516/disabling-disk-cache-in-linux/20215603#20215603
- Nevertheless, Linux seems to heavily utilizes file caching on read operations. To the best of our knowledge, this can not be disabled.


## Completed Benchmarks on Projects
|                               | KSI                           | HPK | Bridge-Operator | Slurm |
|-------------------------------|-------------------------------|-----|-----------------|-------|
| Sysbench CPU                  | ✅                             |     |                 | ✅     |
| Stream Memory                 | ✅                             |     |                 | ✅     |
| Sysbench FileIO rnd           | ✅                             |     |                 | ✅     |
| Sysbench FileIO seq           | ✅                             |     |                 | ✅     |
| ~~Bonnie++ FileIO seq~~       | 💀 bug: no seq read available |     |                 |       |
| Iperf3 Network Throughput     | ✅                             |     |                 | ✅     |
| Netperf Network Latency (TCP) | ✅                             |     |                 | ✅     |
| Workload start up time        | ✅                             |     |                 | ✅     |

✅ = successfully completed
💀 = error occurred / completion not possible