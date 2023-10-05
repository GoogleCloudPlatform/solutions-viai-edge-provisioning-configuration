# Using the solution

## Using multiple cameras, with dedicated ML models, triggered simultaneously

In some situations, you may need to inspect multiple angles or faces of the product.

In practice this means connecting multiple cameras to the solution, and running inspection on them simultaneously.

This section shows how to configure such a multi-cam scenario.

The example uses two cameras, but the same scaling principles should work for a larger number of cameras, as long as the server has enough resources (RAM, storage space, CPU or GPU model acceleration resources etc) to scale the number of camera client containers.

Objective: deploy an inspection station which uses two cameras. Each camera has its own, dedicated camera client application, and its own ML model, trained for that specific camera angle. Then trigger inspection on all cameras simultaneously, and collect all inference results.

In other words, you will have a 1:1:1 mapping running on the edge server:
* Camera 1 is connected camera client 1 which uses ML model 1
* Camera 2 is connected camera client 2 which uses ML model 2
* and so on, if more simultaneous camera angles are needed.

Then youj will trigger all the cameras at the same time and collect all their inference results in a common message queue and/or in BigQuery.

Follow the steps below to deploy a multi-cam setup:

1. Deploy the first camera, first camera client application and first ML model

Follow all the previous sections from [Connecting cameras](./connectingcameras.md) until [Triggering inspection remotely with an MQTT command](./usingtriggeringinspection.md) as per normal.
After completing all the steps, you now have 1 camera, with 1 client application, 1 ML model deployed for that camera, and you are able to trigger inspection with the first camera using MQTT. The first camera is now done.

2. Deploy the second camera client pod

* Find the first camera client’s YAML file `viai-camera-integration.yaml`. It should be located in the `$OUTPUT` folder, after you have originally executed the script `​​0-generate-viai-application-assets.sh`.
The script creates the camera client pod’s YAML file with your system’s specific configurations. If you do not have that file or folder any more, you can re-run the script `0-generate-viai-application-assets.sh` using the same values as before. Refer to chapter [Generating Visual Inspection AI Edge application assets](./createviai.md) in that case.

* Copy the first camera client YAML for the second client with:

```bash
cp viai-camera-integration.yaml viai-camera-integration2.yaml
```

* Edit the `name`, `app` and `claimName` values in the second client YAML files to be non-conflicting.

For example, add ‘2’ to the values. Here’s an example diff between the first/original and second client YAML files:

```text
$ diff viai-camera-integration1.yaml viai-camera-integration2.yaml
5c5
<   name: viai-camera-config
---
>   name: viai-camera-2-config
19c19
<   name: viai-camera-data
---
>   name: viai-camera-2-data
33c33
<   name: viai-camera-1-integration
---
>   name: viai-camera-2-integration
37c37
<       app: viai-camera-1-integration
---
>       app: viai-camera-2-integration
41c41
<         app: viai-camera-1-integration
---
>         app: viai-camera-2-integration
55c55
<           - name: viai-camera-config-volume
---
>           - name: viai-camera-2-config-volume
57,58c57,58
<               claimName: viai-camera-config
<           - name: viai-camera-data-volume
---
>               claimName: viai-camera-2-config
>           - name: viai-camera-2-data-volume
60c60
<               claimName: viai-camera-data
---
>               claimName: viai-camera-2-data
90c90
<             name: viai-camera-config-volume
---
>             name: viai-camera-2-config-volume
92c92
<             name: viai-camera-data-volume
---
>             name: viai-camera-2-data-volume
```

* Deploy the second camera client

```bash
kubectl apply -f viai-camera-integration2.yaml
```

* Monitor the deployment to make sure all the components are running correclty

```bash
watch -n 2 kubectl -n ${NAMESPACE} get pods
```

* Login to the second client container

```bash
kubectl exec -it viai-camera-integration-2-xyz -n ${NAMESPACE} -- /bin/bash
```

* Connect the second, new camera to the same LAN as the server, or to the server directly.

* Follow the steps in the chapter [Connecting cameras](./connectingcameras.md) to discover, connect to, and test the new, second camera.

3. Follow the steps in the chapters from: [Collecting and uploading training images](./collectimages.md) until [Running the model locally](./usinglocalinference.md) with a live camera feed.

NOTE: please export the second ML model with CPU acceleration. At the moment, the scaling works with either all models running on the CPU, or with one model using the GPU, and the other model(s) using the CPU.

By following the chapters listed here, you will:
* Collect training images from the new camera 2
* Train a new ML model for camera 2
* Deploy the camera 2 model to the server
* Test the new ML model 2 with camera 2 using client 2

At this stage, you should have now 2 camera client pods running, as well as 2 ML model deployments and services running

4. Run both camera clients and trigger all cameras’ inspection simultaneously

* Check that you have 2 camera clients and 2 ML models running

```bash
kubectl -n ${NAMESPACE} get pods
```

The output should be similar to this:

```text
NAME                                           READY   STATUS    RESTARTS       AGE
model-mvp2-cpu-1-deployment-785b6f7c5f-jsjlt   1/1     Running   0              110m
model-mvp2-cpu-2-deployment-554497cb7f-hnfmq   1/1     Running   0              110m
mosquitto-6cd7759497-hcgp9                     1/1     Running   3 (154m ago)   7d18h
viai-camera-1-integration-856b878856-8f7js     1/1     Running   0              102m
viai-camera-2-integration-6fcc7b4b5c-6hzv6     1/1     Running   0              107m
```

Take note of the names of the pods for camera integration.

In the example above, `viai-camera-1-integration-856b878856-8f7js` and `viai-camera-2-integration-6fcc7b4b5c-6hzv6`

* Check that both deployments are running

```bash
kubectl -n ${NAMESPACE} get pods
```

The output should be similar to this:

```text
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
model-mvp2-cpu-1-deployment   1/1     1            1           111m
model-mvp2-cpu-2-deployment   1/1     1            1           111m
mosquitto                     1/1     1            1           7d18h
viai-camera-1-integration     1/1     1            1           102m
viai-camera-2-integration     1/1     1            1           107m
```

* Cehck that you have both services runnint

```bash
kubectl -n ${NAMESPACE} get services
```

The output should be similar to this:

```text
NAME               TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)             AGE
model-mvp2-cpu-1   ClusterIP      172.16.200.145   <none>         8602/TCP,8603/TCP   111m
model-mvp2-cpu-2   ClusterIP      172.16.200.248   <none>         8602/TCP,8603/TCP   111m
mosquitto          LoadBalancer   172.16.200.144   192.168.1.24   1883:30522/TCP      7d18h
```

Take note also of the names of each service (`model-mvp2-cpu-1` and `model-mvp2-cpu-2`)

* Login to each camera client.

Following the same names as in the example above:

```bash
kubectl exec -it viai-camera-1-integration-856b878856-8f7js -n ${NAMESPACE} -- /bin/bash

kubectl exec -it viai-camera-2-integration-6fcc7b4b5c-6hzv6  -n ${NAMESPACE} -- /bin/bash
```

* In the shell of camera 1, start the app in daemon mode

In this example, the app is using camera 1 (USB in this example), calling ML model 1, listens for MQTT triggers for starting inspection, and posts the inference results to MQTT.

```bash
python3 camera_client.py --protocol usb --address /dev/video0 --device_id logitech --ml \
    --ml_host model-mvp2-cpu-1 --ml_port 8602 --mode mqtt_sub --mqtt --mqtt_host ${MQTT_HOST}
```


* In the shell of camera 2, start the app in daemon mode

In this example, the app is using camera 2 (RTSP in this example), calling ML model 2, listens for the same MQTT trigger message as client 1, and also posts its inference results to the same MQTT topic as client 1

```bash
python3 camera_client.py --protocol rtsp --address rtsp://192.168.1.104:8556/live/stream2 --device_id nexcom --ml \
    --ml_host model-mvp2-cpu-2 --ml_port 8602 --mode mqtt_sub --mqtt --mqtt_host ${MQTT_HOST}
```

* In a new console window, on another host such as your laptop, start monitoring the MQTT inference results topic

(The IP address is the external IP of the `mosquitto` service)

```bash
mosquitto_sub -h 192.168.1.24 -t viai/results
```

* In another window, send the inspection trigger MQTT message to both camera clients simultaneously

```bash
mosquitto_pub -h 192.168.1.24 -t viai/commands -m get_frame
```

If everything is configured correctly, _both_ camera client windows should display something similar to

```text
MQTT command received: get_frame
{'predictionResult': {'annotationsGroups'..'predictionLatency': '0.024179821s'}
Transmitting ML inference results to local MQTT
Local MQTT transmit complete
```

And the mosquitto_sub window should display _two_ inspection result payloads:

```text
{"predictionResult":.."annotationSpecDisplayName": "defect"}]}]}, "predictionLatency": "0.024179821s"}
{"predictionResult":.."annotationSpecDisplayName": "defect"}]}]}, "predictionLatency": "0.027308149s"}
```


</br>

___

<table width="100%">
<tr><td><a href="./useviai.md">^^^ Using Visual Inspection AI Edge</td><td><a href="./usingbatchprocessing.md">Batch processing inference against a set of image files >>></td></tr>
</table>
