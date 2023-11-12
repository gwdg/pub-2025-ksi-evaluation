#!/bin/bash
set -x # Print each command before execution

#FIXME seq read relies on buffering

# Using volume, because without volume the container storage seems to only exist in memory.

kubectl create --context "$K8S_CLUSTER_NAME" namespace bench
# Create workload as pods or jobs
kubectl create -n bench --context "$K8S_CLUSTER_NAME" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: sysbench
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
          && sysbench fileio --file-total-size=1G --file-num=4 prepare \
          && sysbench fileio --file-total-size=1G --file-num=4 --file-test-mode=seqrd run \
          && sysbench fileio --file-total-size=1G --file-num=4 --file-test-mode=seqwr run \
          && sysbench fileio cleanup
        image: zyclonite/sysbench
        name: sysbench
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

kubectl wait --context "$K8S_CLUSTER_NAME" --for=condition=complete --timeout=10h job/sysbench -n bench

# Print results
kubectl logs job/sysbench -n bench --context "$K8S_CLUSTER_NAME"

# Clean up
kubectl delete --context "$K8S_CLUSTER_NAME" namespace bench