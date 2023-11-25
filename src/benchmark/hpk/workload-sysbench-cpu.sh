#!/bin/bash
set -x # Print each command before execution

kubectl create namespace bench
# Create workload as pods or jobs
kubectl create -n bench -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: sysbench
spec:
  template:
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
      - command:
        - sysbench
        - cpu
        - --threads=56
        - --cpu-max-prime=20000
        - run
        image: zyclonite/sysbench
        name: sysbench
      restartPolicy: Never
EOF

kubectl wait --for=condition=complete --timeout=10h job/sysbench -n bench

# Print results
kubectl logs job/sysbench -n bench

# Clean up
kubectl delete namespace bench