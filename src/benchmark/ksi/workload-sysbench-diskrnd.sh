#!/bin/bash
# Source: https://www.alibabacloud.com/blog/testing-io-performance-with-sysbench_594709
# Performs read and write test separately.

# --file-extra-flags=direct => the file reading and writing mode is changed to direct. FileIO is done directly from user space buffers. See O_DIRECT: https://www.man7.org/linux/man-pages/man2/open.2.html
# Using volume, because without volume the container storage seems to only exist in memory.

set -x # Print each command before execution

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
          && sysbench fileio --file-total-size=1G --file-num=128 prepare \
          && sysbench fileio --file-total-size=1G --file-num=128 --file-test-mode=rndrd --max-requests=0 --file-block-size=256K --file-extra-flags=direct run \
          && sysbench fileio --file-total-size=1G --file-num=128 --file-test-mode=rndwr --max-requests=0 --file-block-size=256K --file-extra-flags=direct run \
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