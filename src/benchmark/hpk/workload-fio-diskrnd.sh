#!/bin/bash
# Source: https://www.thomas-krenn.com/de/wiki/Fio_Grundlagen#Throughput_Test

set -x # Print each command before execution

# Using /tmp, because /tmp is mounted by HPK in each container. In other unmounted directories the storage seems to only exist in memory.


kubectl create namespace bench

# Create workload as pods or jobs
kubectl create -n bench -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: fio
  name: fio
spec:
  securityContext:
    runAsUser: 0
  initContainers:
  - name: init-container-resources
    image: busybox:1.28
    command: ['sh', '-c', "echo Required for Slurm resource allocation cpuPerTask in HPK"]
    resources:
      requests:
        cpu: "28000m"
  containers:
  - command: ["sh", "-c"]
    args:
    - |
      mkdir -p /tmp/fio-bench && cd /tmp/fio-bench \
      && fio --rw=randwrite --name=kube-fio-write --output-format=normal,terse --bs=256k --size=8G \
      && fio --rw=randread --name=kube-fio-read --output-format=normal,terse --bs=256k --size=8G
    image: soerenmetje/fio:3.35
    name: fio
  restartPolicy: Never
EOF

# Wait until pod starts https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#wait
kubectl wait -n bench --for condition=Ready --timeout=3m pod/fio
# Wait until pod stops (there is no possibility to directly wait for pod complete - so this is the workaround https://stackoverflow.com/a/77036091/14355362)
kubectl wait -n bench --for condition=Ready=False --timeout=10h pod/fio

# Print results
kubectl logs pod/fio -n bench

# Clean up
kubectl delete namespace bench

# Reuse created files in each iteration. Files are deleted in bench.sh after run is finished