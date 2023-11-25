#!/bin/bash
set -x # Print each command before execution

# Create workload as pods or jobs
kubectl create -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: millis
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
      - command: ["sh", "-c"]
        args:
        - |
          echo "workload-start-millis \$(date +%s%N | cut -b1-13)"
        image: soerenmetje/millis
        name: millis
      restartPolicy: Never
EOF

kubectl wait --for=condition=complete --timeout=10h job/millis

# Print results
kubectl logs job/millis

# Clean up
kubectl delete job millis