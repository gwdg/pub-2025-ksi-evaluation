#!/bin/bash
# Bonnie++ Documentation:
# https://linux.die.net/man/8/bonnie++
# expects write caching disabled in Linux

#FIXME seq read relies on buffering


set -x # Print each command before execution

kubectl create --context "$K8S_CLUSTER_NAME" namespace bench
# Create workload as pods or jobs
kubectl create -n bench --context "$K8S_CLUSTER_NAME" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: bonnie
spec:
  template:
    spec:
      securityContext:
        runAsUser: 0
      containers:
      - image: soerenmetje/bonnie
        name: bonnie
        command: ["bonnie++"]
        args: ["-d", "/tmp", "-u", "0:0", "-r", "512M", "-s", "1024M", "-b", "-f", "-n", "0", "-x", "1", "-m", "kube-bonnie-result"]
      restartPolicy: Never
EOF

kubectl wait --context "$K8S_CLUSTER_NAME" --for=condition=complete --timeout=10h job/bonnie -n bench

# Print results
kubectl logs job/bonnie -n bench --context "$K8S_CLUSTER_NAME"

# Clean up
kubectl delete --context "$K8S_CLUSTER_NAME" namespace bench