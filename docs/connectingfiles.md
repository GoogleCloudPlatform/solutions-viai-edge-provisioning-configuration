# Connecting the cameras

## Using image files as a data source

<br>

The VIAI Edge solution can also use image files as the source data for visual inspection inference. 

This can be the case if the camera system is external to this server, and the two cannot be integrated directly. 

In this scenario, a local integration is required to take images on the external camera system and then copy the image files to the server hosting this solution. 

Note that the image files need to be on a filesystem that is accessible to the camera integration container. In practice, the best place to copy the images is the kubernetes volume mounted as `/var/lib/viai/camera-data` mounted within the camera integration container. Please refer to the earlier chapter ‘[Connecting to the camera using its Genicam GenTL producer file](./connectinggenicam.md)’ for instructions on how to find and access this mountpoint on the server host OS side, and how to transfer files to that volume. Use the same method as when transferring the GenTL files for Genicam cameras, as shown in the Genicam chapters above.

When you have transferred an image, you can use it as the source 'camera' following these steps:

1. Open a shell to the camera utility container

```bash
kubectl exec -it viai-camera-integration-0 -n ${NAMESPACE} -- /bin/bash
```

2. Run the camera utiltiy, using the image file copied earlier as the data source:

```
export ML_HOST=viai-model
python3 camera_client.py --protocol file --address /var/lib/viai/camera-data/source-image.png \
	--device_id 'filecam' --mode single --ml --ml_host ${ML_HOST} --ml_port 8602 
```

At this point you can start to [Collect images for training](./collectimages.md) in the next section.

</br>

___

<table width="100%">
<tr><td><a href="./connectingcameras.md">^^^ Connecting cameras</td><td><a href="./collectimages.md">Collect images for training >>></td></tr>
</table>




