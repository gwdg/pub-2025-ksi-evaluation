# Setup for Bridge-Operator

IBM/Bridge-Operator requires manual setup before benchmark execution.

1. Set up (or use existing) Kubernetes cluster (e.g. on cloud VM)
2. Set up (or use existing) Slurm cluster
3. Set up (or use existing) S3 instance
4. Add Wireguard tunnel from Kubernetes cluster to Slurm cluster
5. Ensure [HPK Prerequisites](https://github.com/IBM/Bridge-Operator#prerequisites) on Kubernetes cluster node
6. Build HPK on Kubernetes cluster and add CRD to Kubernetes cluster (See: https://github.com/IBM/Bridge-Operator#local-installation-and-deployment *Run as a Deployment inside cluster*)
7. Add secret `mysecret-s3` for S3 and secret `secret-slurm` for the Slurm Rest API to Kubernetes cluster as shown below

```shell
# Exec on Kubernetes cluster
export ENDPOINT=minio-storage.metje.it
export BUCKET=mybucket
export S3_ACCESS_KEY="bridge-operator"
 export S3_SECRET_KEY=
export RESOURCE_URL="http://10.10.41.10:6820/slurm/v0.0.39"
export RESOURCE_USERNAME=smetje
# Generate token on Slurm cluster: scontrol token lifespan=$((3600*24*30)) username=smetje
 export RESOURCE_TOKEN=
export JOBSCRIPT=mybucket:slurm_batch.sh

export S3_SECRET=mysecret-s3
export RESOURCE_SECRET=secret-slurm

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $S3_SECRET
type: Opaque
stringData:
  accesskey: $S3_ACCESS_KEY
  secretkey: $S3_SECRET_KEY
EOF

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $RESOURCE_SECRET
type: Opaque
stringData:
  username: $RESOURCE_USERNAME
  password: $RESOURCE_TOKEN
EOF
```

## Run Example Workload
Using the environment variables from above, the following command is a simple example for submitting a job on the Slurm cluster. 
It uses our patched [container image](https://hub.docker.com/repository/docker/soerenmetje/bridge-operator-slurm-pod/general) that fixes [several issues of the original image](https://github.com/IBM/Bridge-Operator/pull/4).
```shell
kubectl create -f - <<EOF
kind: BridgeJob
apiVersion: bridgejob.ibm.com/v1alpha1
metadata:
  name: slurmjob
spec:
  resourceURL: $RESOURCE_URL
  image: soerenmetje/bridge-operator-slurm-pod:v0.0.2
  resourcesecret: $RESOURCE_SECRET
  imagepullpolicy: Always
  updateinterval: 20
  jobdata:
    jobscript: |
      #!/bin/bash
      echo "Test foo"

    scriptlocation: inline
  jobproperties: |
      {
      "nodes":"1",
      "partition": "linux",
      "tasks": 1,
      "name": "my-test2",
      "current_working_directory": "/nfs/workloads/bridge-operator",
      "environment": {
        "PATH": "/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin",
        "LD_LIBRARY_PATH": ""
        }
      }
  s3storage:
    s3secret: $S3_SECRET
    endpoint: $ENDPOINT
    secure: true
EOF
```

## Debugging

### Operator Logs
For each Bridgejob, the operater creates a pod that handles the submission.
Show the logs of this pod:
```shell
kubectl logs myjobname-bridge-pod