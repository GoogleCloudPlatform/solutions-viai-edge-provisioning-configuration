# Using the solution

## Local inference with images from a camera

This section is a guidance to use the VIAI Edge solution running the model locally. It is a foundation, which should be modified as needed for each particular use case.

To acquire live images from the camera and feed them to the ML container to obtain an inference, run the following steps:

1. If not done earlier, export the 'NAMESPACE` where the VIAI solution is deployed.

```bash
export NAMESPACE=<your_namespace>
```

The default value is `viai-edge`

2. Open a shell in the camera integration container.

```bash
kubectl exec -it viai-camera-integration-0 -n $NAMESPACE -- /bin/bash
```

3. Execute the camera app to request a single image from the camera, and pass that to the ML model container.

You will need the service IP or service name and port where the ML model is deployed [from the previous steps](./modeltoedge.md).

This example is for a Genicam camera.

```bash
export ML_HOST=<your service name>
export ML_PORT=8602

python3 camera_client.py --protocol genicam --gentl /var/lib/viai/camera-config/FLIR_GenTL_Ubuntu_20_04_x86_64.cti \
    --cfg_write --cfg_write_file /var/lib/viai/camera-config/flir-ax5-recommended.cfg \
    --device_id ax5 --mode single --ml --ml_host ${ML_HOST} \
    --ml_port ${ML_PORT}
```

Where:

* `ML_HOST` is the name of your service name.
* `ML_PORT` is the port of your service, `8602` by default.

This example is for a USB camera

```bash
export ML_HOST=<your service name>
export ML_PORT=8602
export ADDRESS=<your camera address>
export DEVICE_ID=<your device id>

python3 camera_client.py --protocol usb --address ${ADDRESS} \
    --device_id ${DEVICE_ID} --mode single --ml --ml_host ${ML_HOST} --ml_port ${ML_PORT}

```

Where:

* `ML_HOST` is the name of your service name.
* `ML_PORT` is the port of your service, `8602` by default.
* `ADDRESS` is the address of the camera, usually `/dev/video0`. Check [this page](./connectingusb.md) to find your camera address.
* `DEVICE_ID` is the device ID of the camera, usually `cam1`. Check [this page](./connectingusb.md) to find your camera device_id.

The app should output the ML model's inference results, which should look similar to this:

```text
{'predictionResult': {'annotationsGroups': [{'annotationSet': {'name': 'projects/199851883686/locations/us-central1/datasets/106648229847760896/annotationSets/5392255711264636928', 'displayName': 'Predicted Classification Labels', 'classificationLabel': {}, 'createTime': '2022-02-15T12:04:13.827789Z', 'updateTime': '2022-02-15T12:04:13.902274Z'},
'annotations': [{'name': 'localAnnotations/0', 'annotationSpecId': '2438893262023426048', 'annotationSetId': '5392255711264636928', 'classificationLabel': {'confidenceScore': 0.52206558}, 'source':
{'type': 'MACHINE_PRODUCED', 'sourceModel': 'projects/199851883686/locations/us-central1/solutions/7580859994631831552/modules/6066366290254102528/models/4464967186816958464'}, 'annotationSpecDisplayName': 'defect'}]}]}, 'predictionLatency': '0.035581135s'}
```

In the output you can see the result as `annotationSpecDisplayName` (which is 'defect' in this example) and the `confidenceScore` and `predictionLatency` among others.

</br>

___

<table width="100%">
<tr><td><a href="./useviai.md">^^^ Using Visual Inspection AI Edge</td><td><a href="./usingbigquery.md">Streaming inference results to BigQuery >>></td></tr>
</table>
