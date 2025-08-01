# Kubernetes Slurm Evaluation

This repository implements scripts to evaluate and benchmark projects that integrate Kubernetes and Slurm.
This project was originally part of a [master’s thesis](https://doi.org/10.25625/GDFCFP) at the Georg August University of Göttingen.
The goal of the thesis was to investigate approaches to run Kubernetes workloads in a Slurm cluster.
In this repository, the following projects are subject of our evaluation:
- [IBM/Bridge-Operator](https://github.com/IBM/Bridge-Operator)
- [CARV-ICS-FORTH/HPK](https://github.com/CARV-ICS-FORTH/HPK)
- [soerenmetje/KSI](https://github.com/soerenmetje/kind-slurm-integration) - Our original KSI implementation
- [gwdg/KSI](https://github.com/gwdg/pub-2025-ksi) - Our improved KSI implementation
- Slurm (without any Kubernetes integration - serves as a reference point / baseline)

> We are aware of further projects such as [Sylabs/WLM-Operator](https://github.com/sylabs/wlm-operator), [SchedMD/slurm-k8s-bridge](https://gitlab.com/SchedMD/training/slurm-k8s-bridge), and [kalenpeterson/kube-slurm](https://github.com/kalenpeterson/kube-slurm). 
> However, these projects are either strongly deprecated and did not pass our minimal functional test 
> or aim at a different goal. Therefore, these projects are not included.

We performed two rounds of evaluations.
The first round covers the CPU, memory, storage, startup time, and network performance of the different projects.
The second round covers only the network performance of the improved KSI implementation.
In our evaluation we used the following benchmark tools to evaluate certain metrics:

| Metric                | Benchmark        | Version       |
|-----------------------|------------------|---------------|
| CPU performance       | Sysbench CPU     | 1.0.20        |
| Memory throughput     | Stream           | 5.10          |
| Storage throughput    | fio (rnd / seq)  | 3.35          |
| Network throughput    | Iperf3           | 3.9           |
| Network latency       | Netperf          | 2.7.1         |
| Workload startup time | Our own approach | not versioned |


## First Evaluation

This first round of evaluations reflects the work presented in the following paper:
- [Running Kubernetes Workloads on Rootless HPC Systems using Slurm](https://www.thinkmind.org/library/CLOUD_COMPUTING/CLOUD_COMPUTING_2025/cloud_computing_2025_2_60_20036.html)

And the master’s thesis of the same name:
- [Running Kubernetes Workloads on Rootless HPC Systems using Slurm](https://doi.org/10.25625/GDFCFP)

## Content
- Shell scripts in `src/benchmark/` to:
  - perform benchmarks on each project
  - write benchmark results into `.csv` files
- Python scripts in `src/plot/` to:
  - read the result files
  - create plots
- Jupyter notebook [analysis.ipynb](src/analysis/analysis.ipynb) to:
  - read the result files
  - print details such as mean, std, and difference to slurm
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
- For benchmarks on Slurm and Bridge-Operator, the benchmark tools has to be installed on the cluster nodes. 
KSI and HPK use container images and therefore do not rely on installed software.
- For benchmarks on Bridge-Operator, an additional machine is required, that runs a Kubernetes cluster. 
In the cluster the Bridge-Operator is required to be up and running. We describe the setup details in [Setup-Bridge-Operator.md](Setup-Bridge-Operator.md).
- For benchmarks on HPK, the HPK components has to be started and configured manually as described in [Setup-HPK.md](Setup-HPK.md).
- To run Fio, iPerf3, and Netperf benchmarks, also manual steps are needed as described below.

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
Regarding the desired RAM, it is a good rule of thumb to choose to benchmark the total filesize that is at least 2 times the available RAM - e.g. 8GiB files for 4GiB RAM.
```shell
# Compile
gcc -o mem-eater mem-eater.c

# Run ./mem-eater <desiredRamInMiB>
./mem-eater 4096
```

### iPerf3 and Netperf
The tools iPerf3 and Netperf operate in a client-server model. 
Therefore, in this setup it is required that the server component is **started manually** on a second node in the Slurm cluster.

In case of iPerf3 the server can be started by following command:
```shell
iperf3 -s -p 5003
```

For the Netperf server you can run:
```shell
netserver -D -p 16604
```
> `-D` to do not daemonize and `-p` to set port.

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

The benchmarks `fio-diskrnd`, `fio-diskseq`, `netperf-latency-tcp`, and `iperf3-bandwidth`,  require manual actions on the slurm cluster before they are executed. This is covered in the [prerequisites sections](#prerequisites).


## Notes
- For testing we disabled writing caching as described here: https://stackoverflow.com/questions/20215516/disabling-disk-cache-in-linux/20215603#20215603
- Nevertheless, Linux seems to heavily utilizes file caching on read operations. To the best of our knowledge, this can not be disabled. 
A solution is to use more file IO size for read or write operations, than memory is available
- To benchmark the project bridge-operator, a Kubernetes cluster is needed. Theoretically, a Kind cluster is sufficient. 
We used a single node Kubernetes cluster deployed in a cloud VM. In order to obtain accurate results in startup-time benchmark, the time on the Slurm node and the VM have to be correct.

## How to Add a New Benchmark?

To add a new benchmark perform the following actions. Replace `<benchmark-name>` with the actual name.

1. Add a Bash script file to each project dir in `src/benchmark`. These files run the benchmark. Use the file name `workload-<benchmark-name>.sh`.
2. Extend the Bash script [src/benchmark/common/parse.sh](src/benchmark/common/parse.sh) in the functions `initResultFile` and `parseLogFile` to add parsing functionality.
3. Add a Python script file named `plot-<benchmark-name>.py` to the directory `src/plot`.
4. Test the process: `/bin/bash src/benchmark/main.sh slurm <benchmark-name>`.

## How to Add a New Project?

To add a new project that should be evaluated do the following actions. Replace `<project-name>` with the actual project name.

1. Add a new directory named `<project-name>` to the directory `src/benchmark`.
2. Add multiple Bash script files for all benchmarks into this directory. Use the file names `workload-<benchmark-name>.sh`. 
For parsing, the benchmark result is expected to be printed to stdout as done in the existing workload bash script files.
3. Extend the Bash script [src/benchmark/main.sh](src/benchmark/main.sh), by adding a new case for the project in the if-elif-else construct marked by `# Start benchmarking`.
4. Extend all Python script files in the directory `src/plot` to add `<project-name>` to the list of `project_dirs`.
5. Extend the Python script [src/plot/common.py](src/plot/common.py) by adding a human-readable project name to the dict `_mapNames`.
6. Test the process: `/bin/bash src/benchmark/main.sh <project-name> stream-memory`.


## Completed Benchmarks on Projects
In the current state, we completed the following benchmarks on each project:

|                               | KSI                                                     | HPK | Bridge-Operator | Slurm                                                   |
|-------------------------------|---------------------------------------------------------|-----|-----------------|---------------------------------------------------------|
| Sysbench CPU                  | ✅                                                       | ✅   | ✅               | ✅                                                       |
| Stream Memory                 | ✅                                                       | ✅   | ✅               | ✅                                                       |
| Fio Disk seq                  | ✅                                                       | ✅   | ✅               | ✅                                                       |
| Fio Disk rnd                  | ✅                                                       | ✅   | ✅               | ✅                                                       |
| ~~Sysbench FileIO rnd~~       | 💀 time-based => can not read / write desired file size |     |                 | 💀 time-based => can not read / write desired file size |
| ~~Sysbench FileIO seq~~       | 💀 time-based => can not read / write desired file size |     |                 | 💀 time-based => can not read / write desired file size |
| ~~Bonnie++ FileIO seq~~       | 💀 bug: no seq read available                           |     |                 |                                                         |
| iPerf3 Network Throughput     | ✅                                                       | ✅   | ✅               | ✅                                                       |
| Netperf Network Latency (TCP) | ✅                                                       | ✅   | ✅               | ✅                                                       |
| Workload start up time        | ✅                                                       | ✅   | ✅               | ✅                                                       |

✅ = successfully completed
💀 = error occurred / completion not possible

## Second Evaluation

This second round of evaluations reflects the work presented in the following paper:
- TBD

The focus of the second evaluation was to compare the network performance of various network drivers for rootless containers when used with KSI including:
- [bypass4netns](https://github.com/rootless-containers/bypass4netns) with Nerdctl
- [slirp4netns](https://github.com/rootless-containers/slirp4netns) with Nerdctl
- [pasta](https://github.com/rootless-containers/pasta) with Podman
- Baseline without containerization

## Content
- Shell scripts in `src2/benchmark/` to:
  - run all benchmarks
  - write benchmark results into `.csv` files
- Python scripts in `src2/plot/` to:
  - read the result files
  - create plots
- CSV result files in `data2/`
- Log files in `logs2/`
- Plot images in `plots2/`

## Prerequisites
To perform the evaluation, a certain prerequisites have to be ensured:
- Compute node with [improved KSI](https://github.com/gwdg/pub-2025-ksi) installed
- KSI should be available in the parent folder, e.g., `../ksi`
- Rootless Nerdctl and Podman 5.x installed
- Slirp4netns installed
- Bypass4netns set up for Nerdctl
- Recent version of Kind installed
- Slurm cluster is not required
- Separate compute node with fast network connection to the first compute node with netperf and iPerf3 installed

### iPerf3 and Netperf
The tools iPerf3 and Netperf operate in a client-server model. 
Therefore, in this setup it is required that the server component is **started manually** on a second node in the Slurm cluster.

In case of iPerf3 the server can be started by following command:
```shell
iperf3 -s -p 5003
```

For the Netperf server you can run:
```shell
netserver -D -p 16604
```
> `-D` to do not daemonize and `-p` to set port.

The IP address of the second compute node must be set in the [main.sh](src2/benchmark/main.sh) script under TEST_SERVER.

## Getting Started
This repository contains a script [main.sh](src2/benchmark/main.sh).
This script is designed to be executed on the first compute node, which has KSI installed.

```shell
/bin/bash src2/benchmark/main.sh
```
After execution, the result file can be obtained in `data2/` and the log files in `logs2/`.

The script automatically executes iperf3 and netperf benchmarks. 

## Completed Benchmarks on Projects
In the current state, we completed the following benchmarks on each project:

|                               | Bypass4netns | Slirp4netns | Pasta | No containerization |
|-------------------------------|--------------|-------------|-------|---------------------|
| iPerf3 Network Throughput     | ✅            | ✅           | ✅     | ✅                   |
| Netperf Network Latency (TCP) | ✅            | ✅           | ✅     | ✅                   |

✅ = successfully completed
