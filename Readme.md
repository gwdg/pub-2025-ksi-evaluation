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

| Metric                | Benchmark        | Version       |
|-----------------------|------------------|---------------|
| CPU performance       | Sysbench CPU     | 1.0.20        |
| Memory throughput     | Stream           | 5.10          |
| Storage throughput    | fio (rnd / seq)  | 3.35          |
| Network throughput    | Iperf3           | 3.9           |
| Network latency       | Netperf          | 2.7.1         |
| Workload startup time | Our own approach | not versioned |

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
- `stream-memory`
- `fio-diskrnd`
- `fio-diskseq`
- `netperf-latency-tcp`
- `iperf3-bandwidth`
- `startup-time`

The benchmarks `fio-diskrnd`, `fio-diskseq`, `netperf-latency-tcp`, and `iperf3-bandwidth`,  require manual actions on the slurm cluster before they are executed. This is covered in the following sections.

### Fio
The fio disk benchmarks heavily depend on the available RAM. 
If more RAM is available than is used as file size in the benchmark, 
usually Linux caches these files. 
As a result, the benchmark measures higher throughputs than are practically possible regarding storage device throughput. 
For reference: typical SATA 3 SSDs suppy 480 MB/s sequential read throughput.

A solution is use direct I/O by adding the parameter `--direct=1` to fio.

Another solution to limit the available RAM during the benchmark by utilizing the tool mem-eater. 
Essentially, this tool allocates RAM until a desired amount of RAM is left. This limits Linux's capabilities to cache the files during the benchmark. 
We provide the sourcecode for mem-eater in [src/benchmark/common/mem-eater.c](src/benchmark/common/mem-eater.c). 
Start mem-eater **manually** before running the fio disk benchmarks. 
Regarding the desired RAM, it is a good rule of thumb to choose to benchmark the total filesize that is at least 4 times the available RAM - e.g. 8GiB files for 2GiB RAM.
```shell
# Compile
gcc -o mem-eater mem-eater.c

# Run ./mem-eater <desiredRamInMiB>
./mem-eater 2048
```

### IPerf 3 and Netperf
The tools IPerf 3 and Netperf operate in a client-server model. 
Therefore, in this setup it is required that the server component is **started manually** on a second node in the Slurm cluster.

In case of iPerf 3 the server can be started by following command:
```shell
iperf3 -s -p 5003
```

For the Netperf server you can run:
```shell
netserver -p 16604
```

## Notes
- For testing we disabled writing caching as described here: https://stackoverflow.com/questions/20215516/disabling-disk-cache-in-linux/20215603#20215603
- Nevertheless, Linux seems to heavily utilizes file caching on read operations. To the best of our knowledge, this can not be disabled. 
A solution is to use more file IO size for read or write operations, than memory is available
- To benchmark the project bridge-operator, a Kubernetes cluster is needed. Theoretically, a Kind cluster is sufficient. 
We used a single node Kubernetes cluster deployed in a cloud VM. In order to obtain accurate results in startup-time benchmark, the time on the Slurm node and the VM have to be correct.

## Completed Benchmarks on Projects
|                               | KSI                                                     | HPK | Bridge-Operator | Slurm                                                   |
|-------------------------------|---------------------------------------------------------|-----|-----------------|---------------------------------------------------------|
| Sysbench CPU                  | ✅                                                       |     | ✅               | ✅                                                       |
| Stream Memory                 | ✅                                                       |     | ✅               | ✅                                                       |
| Fio Disk seq                  | ✅                                                       |     | ✅               | ✅                                                       |
| Fio Disk rnd                  | ✅                                                       |     | ✅               | ✅                                                       |
| ~~Sysbench FileIO rnd~~       | 💀 time-based => can not read / write desired file size |     |                 | 💀 time-based => can not read / write desired file size |
| ~~Sysbench FileIO seq~~       | 💀 time-based => can not read / write desired file size |     |                 | 💀 time-based => can not read / write desired file size |
| ~~Bonnie++ FileIO seq~~       | 💀 bug: no seq read available                           |     |                 |                                                         |
| Iperf3 Network Throughput     | ✅                                                       |     | ✅               | ✅                                                       |
| Netperf Network Latency (TCP) | ✅                                                       |     | ✅               | ✅                                                       |
| Workload start up time        | ✅                                                       |     | ✅               | ✅                                                       |

✅ = successfully completed
💀 = error occurred / completion not possible