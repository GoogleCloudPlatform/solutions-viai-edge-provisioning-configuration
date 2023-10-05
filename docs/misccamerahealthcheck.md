# Using the solution

## Camera connection health checks

The utility supports checking the health of a camera connection.

In practice, the utility requests a frame from the camera. If the operation is successful, and the camera returns a valid image, the utility displays: `True`, and exists normally with code `0`. In case of an error, the error is displayed, the log output is `False`, and the utility exit code is `1`.

To execute the healthcheck, just add the command-line argument `--health_check` to
the utility. You will also need to pass valid arguments for the target camera, i.e camera protocol and address.

Example command:

```bash
python3 camera_client.py --protocol usb --device_id 'usbcam' --address /dev/video0 --mode single --img_write --health_check 2>/dev/null
```

Example output:

```
INFO:root:Camera health check result: True
```

</br>

___

<table width="100%">
<tr><td><a href="./useviai.md">^^^ Using Visual Inspection AI Edge</td><td><a href="./miscautomaticdeployment.md">Automatic deployment options >>></td></tr>
</table>
