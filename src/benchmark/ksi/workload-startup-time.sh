#!/bin/bash
set -x # Print each command before execution

# Create workload as pods or jobs
kubectl create --context "$K8S_CLUSTER_NAME" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: millis
spec:
  template:
    spec:
      securityContext:
        runAsUser: 0
      containers:
      - command: ["sh", "-c"]
        args:
        - |
          echo "workload-start-millis $(date +%s%N | cut -b1-13)"
        image: soerenmetje/millis
        name: millis
      restartPolicy: Never
EOF

kubectl wait --context "$K8S_CLUSTER_NAME" --for=condition=complete --timeout=10h job/millis

# Print results
kubectl logs job/millis --context "$K8S_CLUSTER_NAME"

# Clean up
kubectl delete --context "$K8S_CLUSTER_NAME" job millis