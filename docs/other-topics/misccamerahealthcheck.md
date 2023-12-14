---
title: Camera health check
layout: default
nav_order: 3
parent: Other Topics
---
# Using the solution

## Camera connection health checks

The utility supports checking the health of a camera connection.

In practice, the utility requests a frame from the camera. If the operation is successful, and the camera returns a valid image, the utility displays: `True`, and exists normally with code `0`. In case of an error, the error is displayed, the log output is `False`, and the utility exit code is `1`.

To execute the healthcheck, just add the command-line argument `--health_check` to
the utility. You will also need to pass valid arguments for the target camera, i.e camera protocol and address.

Run on Edge Server
{: .label .label-green}

Example command:

```bash
python3 camera_client.py --protocol usb --device_id 'usbcam' --address /dev/video0 --mode single --img_write --health_check 2>/dev/null
```

Example output:

```text
INFO:root:Camera health check result: True
```
