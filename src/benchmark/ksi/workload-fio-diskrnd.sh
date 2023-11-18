#!/bin/bash
# Source: https://www.thomas-krenn.com/de/wiki/Fio_Grundlagen#Throughput_Test

set -x # Print each command before execution

# Using volume, because without volume the container storage seems to only exist in memory.

kubectl create --context "$K8S_CLUSTER_NAME" namespace bench
# Create workload as pods or jobs
kubectl create -n bench --context "$K8S_CLUSTER_NAME" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: fio
spec:
  template:
    spec:
      securityContext:
        runAsUser: 0
      containers:
      - command: ["sh", "-c"]
        args:
        - |
          cd /app \
          && mkdir -p tmp && cd tmp \
          && fio --rw=randwrite --name=kube-fio-write --output-format=normal,terse --bs=256k --size=8G \
          && fio --rw=randread --name=kube-fio-read --output-format=normal,terse --bs=256k --size=8G
        image: soerenmetje/fio:3.35
        name: fio
        volumeMounts:
          - name: project-vol
            mountPath: /app
      restartPolicy: Never
      volumes:
        - name: project-vol
          hostPath:
            path: /app
            type: Directory
EOF

# Reuse created files in each iteration. Files are deleted in bench.sh after run is finished

kubectl wait --context "$K8S_CLUSTER_NAME" --for=condition=complete --timeout=10h job/fio -n bench

# Print results
kubectl logs job/fio -n bench --context "$K8S_CLUSTER_NAME"

# Clean up
kubectl delete --context "$K8S_CLUSTER_NAME" namespace bench