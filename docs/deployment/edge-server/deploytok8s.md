---
title: Deploy to Kubernetes
layout: default
parent: Deploy to Server
grand_parent: Deployment
nav_order: 2
---
# Deployment

## Deploy the solution to an existing Kuberentes cluster

<br>

Follow this section to deploy the VIAI Edge solution __only if__ all the criteria below are met. At this time, deploying the solution to an existing kubernetes cluster attached to Anthos uses a different script set. Combining both is a work in progress.

__Requirements__

* You already have a Kubernetes cluster running.
* The kubernetes is already attached to Anthos.
  * If it's not attached yet, [follow this instructions](https://cloud.google.com/anthos/clusters/docs/multi-cloud/attached/previous-generation/how-to/attach-kubernetes-clusters) to attach the cluster to Anthos.
* The required NVIDIA drivers are already installed on the kubernetes cluster.
  * If they are not installed yet, [follow this instructions](https://docs.nvidia.com/datacenter/cloud-native/kubernetes/install-k8s.html) to install the NVIDIA drivers for the Kubernetes cluster, then [follow this instructions](https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/index.html#ubuntu-lts) to install NVIDIA drivers on Ubuntu server.

<br>

__Deploying the Visual Inspection AI Edge application__

Since the existing cluster has been attached to Anthos, we will connect to the existing cluster and apply Kubernetes YAML files to the cluster remotely.

You can do this in Cloud Shell or a Workstation with Google Cloud SDK installed. If you are on a workstation, you need to follow step 1 below to install `gke-gcloud-auth-plugin`. If you are on Cloud Shell, you can skip step 1.

1. Install `gke-cloud-auth-plugin`

    ```bash
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

    sudo apt-get update && sudo apt-get install google-cloud-cli

    sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
    ```

2. If you are using a different machine than you used to [generate the VIAI application assets]({% link deployment/createviai.md %}), copy the contents of the output folder to the local machine.

3. Run the commands below:

    ```bash
    gcloud auth login
    gcloud container hub memberships get-credentials ${MEMBERSHIP} --project ${DEFAULT_PROJECT}

    cd $OUTPUT_FOLDER/kubernetes/
    kubectl apply -f ./namespace.yaml
    kubectl apply -f ./secret_pubsub.yaml
    kubectl apply -f ./secret_image_pull.yaml
    kubectl apply -f ./viai-camera-integration.yaml
    kubectl apply -f ./mosquitto.yaml
    ```

    Where:

    * `MEMBERSHIP` The membership name of the existing edge server.
    * `DEFAULT_PROJECT` the ID of the Google Cloud project to provision the resources to deploy the solution.
    * `OUTPUT_FOLDER` The folder that contains application assets generated at the [previous step]({% link deployment/createviai.md %}).

At this point the cluster is ready, you can continue in the [Connecting the cameras]({%link connecting-cameras/connectingcameras.md %}) section.
