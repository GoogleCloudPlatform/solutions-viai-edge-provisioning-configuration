# Collecting and uploading training images

## Collecting training images

<br>

This section shows the steps and instructions to integrate Visual Inspection AI Edge with the Visual Inspection AI Anomaly Detection service. For exact steps with the other types of VIAI models (Assembly inspection, Cosmetic inspection), please refer to the [Visual Inspection AI product documentation](https://cloud.google.com/solutions/visual-inspection-ai).

To create a custom ML model we need to collect training images from your particular use case. Including a good quality, high number of training images may lead to a higher quality ML model.

The images are acquired from the camera and written on disk on the server, from where they are uploaded in batch to to Google Cloud Storage (GCS) with the gsutil rsync command. Once the images are in GCS, they can be subsequently used as source data by the Visual Inspection AI cloud service during ML model training.

When creating the training dataset in Visual Inspection AI, you will need to label the images. This tells the service which images are examples of anomalies and which are normal. Labelling the images is done in the VIAI console.

<br>

__Preparing to collect the training images__

This step is highly use-case specific. You should create an apropriate environment where you can use the camera connected to the edge server to take images of both normal, and abnormal situations for the products to be inspected.

Here are some general principles:
* Setup a controlled test environment which minimizes external influences such as ambient light affecting the camera exposure.
* Place the camera in its intended position. Take single shots to verify that the camera can fully see the objects to be inspected and not much extra space beyond them, to maximize the number of pixels covering the objects.
* Adjust the camera exposure, focus, focal length etc parameters and lock them in place, to avoid auto-adjustments changing the settings between shots.
* Ensure that the camera does not move or shake when taking pictures.
* Ensure that the objects do not move, or move too fast when taking the images, resulting in motion blur or rolling shutter effects.
* Setup consistent, even lighting and eliminate variable ambient light sources such as open windows nearby.

<br>

__Collecting and uploading training images__

Use the following commands to collect at least 100 examples of ‘normal’ images and at least a few dozen examples of ‘defective’ images. Training the model with more examples may lead to better results. The quality of these images will have a dramatic effect in the accuracy of the ML model. Take your time to generate the best training dataset possible.

1. In the edge server, create a folder called, for example, `model1` with two sub-folders called `normal` and `defect`

```bash
mkdir -p /var/lib/viai/camera-data/model1/normal
mkdir -p /var/lib/viai/camera-data/model1/defect
```

2. Open a shell to the camera utility container

```bash
kubectl exec -it -n $NAMESPACE viai-camera-integration-0 -- /bin/bash
```

3. Use the camera client app to generate the images for the `normal` label.

Make sure you change the parameters based on your environment. These examples take 150 images in continuous mode.
If you need to change the objects, you can change the `--sleep` paramater or use the examples in the next section
using `interactive` mode.

* Genicam example

```bash
python3 camera_client.py --protocol genicam --gentl /var/lib/viai/camera-config/<your-camera-gentl-file> \
    --cfg_write --cfg_write_file <your-camera-required-settings>.cfg --device_id <camera-id> --img_write \
    --img_write_path /var/lib/viai/camera-data/model1/normal/ --mode continuous --sleep 0 --count 150
```

* RTSP & ONVIF example (ONVIF cameras provide RTSP URLs for the video streams, ONVIF is just the control plane)

```bash
python3 camera_client.py --protocol rtsp --device_id <camera-id> --address <rtsp://address:port> \
    --cam_user <optional username> --cam_passwd <optional password> --img_write \
    --img_write_path /var/lib/viai/camera-data/model1/normal/ --mode continuous --sleep 0 --count 150
```

* USB example

```bash
python3 camera_client.py --protocol usb --device_id <camera-id> --address </dev/video0|1|2..> \
    --img_write --img_write_path /var/lib/viai/camera-data/model1/normal/ --mode continuous \
    --sleep 0 --count 150 2>/dev/null
```

* File example

    In case of files, you should already have a collection of normal and defective images, collected separately. Use this set of images to build your VIAI dataset, following the instructions below.


If you need to place good quality objects in front of the camera 1 by 1, you can also collect the training images one at a time, executing the following command for each camera view of the object, using `--mode single`, as many times as needed. Or you can run the utility in interactive mode, with switch: `--mode interactive`.
With the interactive mode, the utility will take a new image every time you press '<enter>'.

Generate at least 100 normal examples by running:

* Genicam example

```bash
python3 camera_client.py --protocol genicam --gentl /var/lib/viai/camera-config/<your-camera-gentl-file> \
    --cfg_write --cfg_write_file <your-camera-required-settings>.cfg --device_id <camera-id> \
    --img_write --img_write_path /var/lib/viai/camera-data/model1/normal/ --mode interactive
```

* RTSP & ONVIF example

```bash
python3 camera_client.py --protocol rtsp --address --address <rtsp://address:port> \
    --cam_user <optional username> --cam_passwd <optional password> --device_id <camera-id> \
    --img_write --img_write_path /var/lib/viai/camera-data/model1/normal/ --mode interactive
```

* USB example

```bash
python3 camera_client.py --protocol usb --device_id <camera-id> --address </dev/video0|1|2..> \
    --img_write --img_write_path /var/lib/viai/camera-data/model1/normal/ --mode interactive 2>/dev/null
```

* File example

    In case of files, you should already have a collection of normal and defective images, collected separately. Use this set of images to build your VIAI dataset, following the instructions below.

4. Use the camera client app to generate the images for the `defect` label.

Use the same examples as above, switching `--img_write_path` from `/var/lib/viai/camera-data/model1/normal/` to `/var/lib/viai/camera-data/model1/defect/`.

Take as many images for this label as possible (25 minimum).

<br>

__Cropping the camera images__

Optimally, the object that you inspect should fill most of the camera frame. The best way to achieve this is with camera positioning and lenses. But if necessary, you can also use the crop feature of the camera client application, to remove extra pixels from the edges of the image.

To use the crop feature, add all of the following command-line parameters:

`--crop_left 0 --crop_top 0 --crop_right 320 --crop_bottom 200`

In the above example, the utility will crop the raw camera frame at coordinates (0,0),(320,200), resulting in a 320x200 output image.

Note: if you specify both image crop, and image resize arguments, crop takes place first, and then the cropped image is resized to the desired final resolution.

<br>

__Upload the training images to Google Cloud__

Upload the two folders of training images to Google Cloud Storage using the following commands:

1. Open a shell to the camera utility container if you exited it after the previous steps

```bash
kubectl exec -it -n $NAMESPACE viai-camera-integration-0 -- /bin/bash
```

2. Initialize the Google Cloud SDK that is installed inside the camera integration container

```bash
gcloud init
```

3. Find the bucket created by the Terraform script in Google Cloud Storage

```bash
gsutil ls gs://
```

The command should output similar to this. Take note of the bucket path:

```text
gs://viai-us-model-training-data-<your_id>/
```

4. Upload the directories of images to GCS

```bash
gsutil -m rsync -r /var/lib/viai/camera-data/model1 gs://viai-us-model-training-data-<your_id>/model1/
```

5. Verify that the sub-folders have been created in GCS

```bash
gsutil ls gs://viai-us-model-training-data-<your_id>/model1/
```

The output should be similar to:

```text
gs://viai-us-model-training-data-<your_id>/model1/defect/
gs://viai-us-model-training-data-<your_id>/model1/normal/
```

<br>

At this point the training dataset is ready to be used by VIAI. You can continue to the section to [train your ML model in VIAI](./trainviai.md)



<br>

___

<table width="100%">
<tr><td><a href="./trainviai.md">Train your ML model in VIAI >>></td></tr>
</table>
