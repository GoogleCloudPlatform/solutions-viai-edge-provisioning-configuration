# Using the solution

## Improving GPU utilization in Kubernetes

<br>

The default setup of Visual Inspection AI Edge allows you to run one GPU model at a time.

If the workload is not latency sensitive and you want to run multiple VIAI models on the edge server, there are different strategies to consider:
* Run these models in CPU mode.
* Consider NVIDIA’s [concurrency mechanisms](https://developer.nvidia.com/blog/improving-gpu-utilization-in-kubernetes/), such as MIG / vGPU.
* Enable NVIDIA GPU Time-slicing.

In this section, you will learn how to enable GPU time-slicing on the Visual Inspection AI Edge server.

Note: According to the NVIDIA documentation, time-slicing is NOT recommended for production environments. If you need to share GPU resources across multiple models on production environments, consider installing more GPUs or leverage GPUs that support MIG.

__Enabling time-slicing on th edge server__

1. Install Helm in the edge server

```bash
snap install helm --classic
```

2. Configure NVIDIA Helm repo.

```bash
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update
```

3. Prepare the time-slicing configuration file.

Note that in this sample configuration, VIAI Edge advertises 10 replicas to the Anthos runtime. If you have two GPUs installed on the edge server, each will have 10 replicas, meaning device plugins advertise 20 GPUs to the Anthos.

You should monitor your GPU memory utilization in your development environment to
understand actual requirements of running your machine learning models, and decide what is the best value for your workload. 

To monitor GPU utilization, you use tools such as [nvitop](https://github.com/XuehaiPan/nvitop).

```bash
cat << EOF > /tmp/dp-example-config.yaml
version: v1
flags:
  migStrategy: "none"
  failOnInitError: true
  nvidiaDriverRoot: "/"
  plugin:
    passDeviceSpecs: false
    deviceListStrategy: "envvar"
    deviceIDStrategy: "uuid"
  gfd:
    oneshot: false
    noTimestamp: false
    outputFile: /etc/kubernetes/node-feature-discovery/features.d/gfd
    sleepInterval: 60s
sharing:
  timeSlicing:
    resources:
    - name: nvidia.com/gpu
      replicas: 10
EOF
```

4. Delete the existing NVIDIA device plugin.

```bash
kubectl delete daemonset nvidia-device-plugin-daemonset -n kube-system
```

5. Install new NVIDIA device plugin with the time-slicing configuration file.

```bash
export SETUP_DIR=/var/lib/viai
export ANTHOS_MEMBERSHIP_NAME=<ANTHOS MEMBERSHIP NAME>
export KUBECONFIG=$SETUP_DIR/bmctl-workspace/$ANTHOS_MEMBERSHIP_NAME/$ANTHOS_MEMBERSHIP_NAME-kubeconfig

helm install nvdp nvdp/nvidia-device-plugin \
    --version=0.12.2 \
    --namespace nvidia-device-plugin \
    --create-namespace \
    --set gfd.enabled=true \
    --set-file config.map.config=/tmp/dp-example-config.yaml
```

Where:
* `SETUP_DIR`: is the folder that contains VIAI Edge setup scripts. Defaults to `/var/lib/viai`
* `ANTHOS_MEMBERSHIP_NAME` Anthos membership of the edge server.
* `KUBECONFIG` Anthos cluster Kube configuration file path. Defaults to: `$SETUP_DIR/bmctl-workspace/$ANTHOS_MEMBERSHIP_NAME/$ANTHOS_MEMBERSHIP_NAME-kubeconfig`

6. Wait until the GPU resources are advertised.

Wait for around a minute and run `kubectl describe node`, you should see that now the Anthos cluster node has 10 `nvidia.com/gpu` resources are allocatable.


<br>
___

<table width="100%">
<tr><td><a href="./useviai.md">^^^ Using Visual Inspection AI Edge</td></tr>
</table>
