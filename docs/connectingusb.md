# Connecting the cameras

## Connecting USB cameras

<br>

The camera utility can discover USB (web) cameras which are directly connected to a USB port on the host server. 

In practice, the software scans the linux OS for video devices from `/dev/video0` until `/dev/video9`, i.e the first 10 connected USB devices. 

If a device exists, the utility will try to open the device as a camera. If this works, it’s reported as an available camera. 

The scanning will produce warnings when incompatible devices are scanned - you can ignore those warnings.

<br>

__Scan for USB cameras__

1. On the edge server, use the `v2l4` tool to check if the camera is connected and is detected.

```bash
sudo apt-get install v4l-utils 
v4l2-ctl --list-devices
```

The output should be similar to this:

```
Logitech Webcam C930e (usb-0000:00:14.0-8):
	/dev/video0
	/dev/video1
	/dev/media0
```

2. Open a shell to the camera utility container

```bash
kubectl exec -it -n $NAMESPACE viai-camera-integration-0 -- /bin/bash
```

3. From the utility container, scan the local server for USB cameras

```bash
python3 camera_client.py --protocol usb --scan
```

The output should be similar to this:

```
Discovering USB cameras..
USB cameras found:
Address: /dev/video0 | Model: Logitech Webcam C930e | # of Properties: 275
```

    The example above shows a valid camera connected to /dev/video0


With the information from the last step, you can start to [Collect images for training](./collectimages.md) in the next section.

</br>

Optionally, you can continue reading to understand how to manage the configuration of a USB camera:

__Managing the configuration of USB cameras__

The VIAI Edge utility supports reading and writing camera runtime configurations for Genicam and USB cameras.

* Query the camera's current runtime configurations and output them to an editable text file (replace the device address with your value, usually `/dev/video0`)

```bash
python3 camera_client.py --protocol usb --address /dev/video0 --device_id cam1 --mode none  \
    --cfg_read --cfg_read_file /var/lib/viai/camera-config/current.cfg 2>/dev/null
```

The output should be similar to:

```
2022-09-13 02:59:42,296 - root - INFO - USB cameras found: ['/dev/video0']
Using camera: /dev/video0
INFO:root:Querying camera runtime configs and saving to: /var/lib/viai/camera-config/current.cfg
```

* Verify the generated camera configuration file

```bash
head -5 /var/lib/viai/camera-config/current.cfg
```

The output should be similar to:

```
CAP_PROP_APERTURE = -1.0
CAP_PROP_AUTOFOCUS = 1.0
CAP_PROP_AUTO_EXPOSURE = 3.0
CAP_PROP_AUTO_WB = 1.0
CAP_PROP_BACKEND = 200.0
```

* To change a configuration parameter value, edit the generated configuration file with your favorite editor

```bash
vi /var/lib/viai/camera-config/current.cfg
```

* Write the updated configuration back to the camera

```bash
python3 camera_client.py --protocol usb --address /dev/video0 --device_id cam1 --mode none \
    --cfg_write --cfg_write_file /var/lib/viai/camera-config/current.cfg 2>/dev/null
```

The output should be similar to this:

```
2022-09-13 03:01:34,150 - root - INFO - Reading config from input file: /var/lib/viai/camera-config/current.cfg
INFO:root:Writing config to the camera: CAP_PROP_APERTURE = -1.0
INFO:root:Writing config to the camera: CAP_PROP_AUTOFOCUS = 1.0
...
```

<br>

___

<table width="100%">
<tr><td><a href="./connectingcameras.md">^^^ Connecting cameras</td><td><a href="./collectimages.md">Collect images for training >>></td></tr>
</table>




