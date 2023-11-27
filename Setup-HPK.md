# Setup for HPK


HPK requires manual setup before benchmark execution.
After the [prerequisites of HPK](https://github.com/CARV-ICS-FORTH/HPK/blob/main/deploy/aws/install-hpk-requirements.sh) are ensured, one can start the two HPK components.
Run manually in separate screens:
``` bash
make run-kubemaster
```

``` bash
make run-kubelet
```

Now, kubectl should be available:
``` bash
export KUBE_PATH=~/.k8sfs/kubernetes/
export KUBECONFIG=${KUBE_PATH}/admin.conf
kubectl get nodes
```

## Debugging

HPK seems to be not very robust. In case of issues you may try:
- Restart the HPK components (kubemaster and kubelet)
- Delete the HPK state in `$HOME/.hpk` between stopping and starting HPK components: `rm -rf $HOME/.hpk`