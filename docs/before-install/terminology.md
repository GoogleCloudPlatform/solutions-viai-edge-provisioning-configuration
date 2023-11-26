---
title: Terminology
layout: default
nav_order: 1
parent: Before Install
---
# Terminology

The following terms are important for understanding how to design and implement a Visual Inspection AI Edge deployment:

* __Edge server.__ A server that you deploy at the [edge of your environment](https://www.lfedge.org/2020/08/18/breaking-down-the-edge-continuum/) which is running the Visual Inspection AI Camera applications to capture photos, invoke machine learning
models, fetch inference results and send results to the backend.

* __Cloud Resources.__ Services that run in the Google Cloud platform to receive inference
results, storing results, developing machine learning models and deploy the
containerized models to the edge server.

* __Visual Inspection AI edge applications.__ Applications that are running on the edge
server, this includes the camera application that connects to the camera, captures
photos and gets machine learning model inference results from a machine learning
model, and the Visual Inspection AI machine learning models which are packed as a
container image and running on the edge server.

* [__Visual Inspection AI Service.__](https://cloud.google.com/solutions/visual-inspection-ai) A Google Cloud service hosted, managed and operated
by Google Cloud. You use the service to train your Visual Inspection AI models.

* __Target edge environment.__ The physical location where your edge server will be
deployed.

* __Setup worksation__ A Linux or macOS desktop or laptop, with access to the internet and USB ports, that will be used to setup the Google Cloud assets and prepare the Edge server configuration and operating system.

During the deployment process, you will be asked to perform some actions in the __setup workstation__ or in the __edge server__. To help you identify more clearly which one to use, you will find labels before the group of steps:

Run on Setup Worksation
{: .label .label-blue}

Run on Edge Server
{: .label .label-green}
