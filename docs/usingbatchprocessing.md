# Using the solution

## Batch processing inference against a set of image files

The client application also supports batch processing, as a handy way to test trained ML models against a large set of images. In batch processing mode, the flow is as follows:

* The user prepares a set of images to run inference against. These are typically images saved from the camera earlier, with known labels - i.e, known to be good and known to be defective examples
* The user stores the images on the VIAI Edge server, in a directory that the camera client application can access
* The user runs the camera client in batch mode against the root directory that contains the images
* The application finds all image files inside the directory and its subdirectories
* The application forwards each image in turn to the VIAI ML model and gets the inference results
* Optionally, the inference results can be forwarded to an MQTT message queue, to be received by another host and/or for the results to be redirected to a text file for further analysis

The following steps will run batch mode inference against a set of images.

1. Log in to the VIAI Edge server as user `viai-admin`

2. Check which physical volumes are mounted to the camera application

```bash
kubectl -n ${NAMESPACE} get pods

kubectl -n ${NAMESPACE} describe pod viai-edge-camera-integration-<suffix>

kukbectl describe pv <pv-id>
```

You should see a mount point similar to: `/mnt/localpv-share/pvs/3/` which is mounted as `/var/lib/viai/camera-data` inside the camera client container.

3. Copy your testing image dataset to the VIAI Edge server, to the directory found above

4. Login to the container

```bash
kubectl exec -it viai-camera-integration -- /bin/bash
```

5. Verify that the container can see the image files

```bash
ls -l /var/lib/viai/camera-data/
```

6. (Reccomended) On another host, start receiving ML inference results, by subscribing to an MQTT topic

```bash
mosquitto_sub -h 192.168.1.24 -t viai/results
```

Where `192.168.1.24` is the IP address of the mosquitto service running in Kubernetes on the same server.

You can find the mosquitto service IP and ML model service name with:

```bash
kubectl -n ${NAMESPACE} get services
```

7. Start batch processing all images in the dataset, and forwarding the inference results to MQTT

```bash
python3 camera_client.py --protocol file --address /var/lib/viai/camera-data/good/ --device_id good_batch --ml \
    --ml_host <ml-model-service-name> --ml_port 8602 --mode batch --mqtt --mqtt_host ${MQTT_HOST}
```

You should see the camera application iterate through all the input files, and in the second host `mosquitto_sub` window, you should start receiving the ML model inference result JSON records.

You can redirect the results to a text file on the second host, by modifying the `mosquitto_sub` command as follows:

```bash
mosquitto_sub -h 192.168.1.24 -t viai/results >> good_batch_model-version-xyz.txt
```



</br>

___

<table width="100%">
<tr><td><a href="./useviai.md">^^^ Using Visual Inspection AI Edge</td></tr>
</table>
