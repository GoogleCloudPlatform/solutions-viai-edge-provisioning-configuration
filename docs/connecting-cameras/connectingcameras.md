---
title: Connecting Cameras
layout: default
nav_order: 4
has_children: true
---
# Connecting the cameras

Before connecting the cameras, make sure you follow these steps:

The Anthos Bare Metal uses a Connect gateway to authenticate your Google Cloud identity and provides the connection to the cluster's API server via the Connect service. The gateway does not currently support exec/attach/proxy/port-forward. To use these functions you’d have to connect to the Kubernetes API server via its private endpoint.

During the Anthos Bare Metal setup, the `bmctl` tool creates a `kubeconfig` to connect to the Anthos cluster on Bare Metal, you can reuse this config to perform the required exec tasks to connect the cameras.

The kubeconfig file is stored in the edge server at `/var/lib/viai/bmctl-workspace/${MEMBERSHIP}/${MEMBERSHIP}-kubeconfig`

Where:

* `MEMBERSHIP` Is the Anthos membership name you specified while generating Anthos installation assets.

<br>

__Logging in to the edge server__

The default viai-admin user is assigned to the sudo group. Login to the edge server and run:

```bash
sudo su
export KUBECONFIG=/var/lib/viai/bmctl-workspace/${MEMBERSHIP}/${MEMBERSHIP}-kubeconfig
export NAMESPACE=<YOUR APPLICATION NAMESPACE>
```

Where:

* `MEMBERSHIP` is the Anthos Cluster name.
* `NAMESPACE` is the application namespace. Default is `viai-edge`.

<br>

The following sections show how to connect different types of cameras to the server. Follow the instructions below for your specific camera type(s).

_Note:_ You can connect multiple different types of cameras to the server, but right now, the viai-camera-integration application container can only use one camera at a time. We are testing running multiple camera client containers & connected cameras simultaneously and will update this document accordingly.

* [Connecting Genicam cameras]({% link connecting-cameras/connectinggenicam.md %})
* [Connecting ONVIF-enabled RTSP cameras]({% link connecting-cameras/connectingonvif.md %})
* [Connecting simple RTSP cameras]({% link connecting-cameras/connectingrtsp.md %})
* [Connecting USB cameras]({% link connecting-cameras/connectingusb.md %})
* [Using image files as data source]({% link connecting-cameras/connectingfiles.md %})
* [Connecting thermal cameras]({% link connecting-cameras/connectingthermal.md %})
