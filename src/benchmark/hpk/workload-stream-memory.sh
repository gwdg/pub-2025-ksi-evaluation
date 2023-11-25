#!/bin/bash
set -x # Print each command before execution

kubectl create namespace bench
# Create workload as pods or jobs
kubectl create -n bench -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: stream
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
      - image: soerenmetje/stream
        name: stream
        command: ['sh', '-c', "cd /app && /bin/bash /app/stream.sh"]
        env:
        - name: ARRAYSIZE
          value: "100000000"
        - name: THREADS
          value: "56"
      restartPolicy: Never
EOF

kubectl wait --for=condition=complete --timeout=10h job/stream -n bench

# Print results
kubectl logs job/stream -n bench

# Clean up
kubectl delete namespace bench