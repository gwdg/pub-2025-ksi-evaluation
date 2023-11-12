#!/bin/bash
set -x # Print each command before execution

kubectl create --context "$K8S_CLUSTER_NAME" namespace bench
# Create workload as pods or jobs
kubectl create -n bench --context "$K8S_CLUSTER_NAME" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: stream
spec:
  template:
    spec:
      securityContext:
        runAsUser: 0
      containers:
      - image: soerenmetje/stream
        name: stream
        env:
        - name: ARRAYSIZE
          value: "100000000"
        - name: THREADS
          value: "56"
      restartPolicy: Never
EOF

kubectl wait --context "$K8S_CLUSTER_NAME" --for=condition=complete --timeout=10h job/stream -n bench

# Print results
kubectl logs job/stream -n bench --context "$K8S_CLUSTER_NAME"

# Clean up
kubectl delete --context "$K8S_CLUSTER_NAME" namespace bench