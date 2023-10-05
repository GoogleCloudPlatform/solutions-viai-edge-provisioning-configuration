# Connecting the cameras

## Connecting ONVIF-enabled RTSP cameras

<br>

__Prepare your camera__

Install and configure your IP camera using its management tools and ensure that...

1. Has ONVIF enabled for remote management and discovery.
2. Provides at least one RTSP stream URL.
3. ONVIF, and RTSP can have username/password authentication enabled, if necessary, or can be left unauthenticated.
4. The camera is located in the same IP LAN segment as the server. ONVIF discovery uses broadcast messages which are not routed between LAN subnets. Avoiding routed connections also reduces any video stream data processing latency or bandwidth issues.

<br>

__Scan for ONVIF cameras__

1. Open a shell to the camera utility container

```bash
kubectl exec -it viai-camera-integration  -n ${NAMESPACE} -- /bin/bash
```

2. Scan the local LAN segment for any ONVIF-enabled cameras

    Note: the network scan uses the WSDiscovery protocol, which sends standards-defined broadcast messages to discover devices that advertise web services. Next, the utility filters the found devices for those that support the ONVIF specification. Finally, the utility tries to query all found ONVIF cameras, using the ONVIF protocol, and get their RTSP stream addresses.

    Note: if your camera has access control enabled using a username/password pair, you need to provide these credentials to enable the ONVIF query for RTSP streams information.

* For unauthenticated cameras, run:

```bash
python3 camera_client.py --protocol onvif --scan
```

* For cameras with authentication enabled, run:

```bash
python3 camera_client.py --protocol onvif --scan --cam_user <username> --cam_passwd <pwd>
```

The output should be similar to:

```
Discovering ONVIF cameras on the network..
ONVIF cameras found: [{'uuid': '2419d68a-2dd2-21b2-a205-ec', 'addr': '192.168.1.105', 'port': '8000'}]
Querying found ONVIF cameras for RTSP URIs..
ONVIF RTSP addresses found: ['rtsp://192.168.1.105:554/h264Preview_01_main', 'rtsp://192.168.1.105:554/h264Preview_01_sub']
```

    The example above has discovered two cameras, which can be used in the next section.


At this point, the camera is connected and ready to use. You can start to [Collect images for training](./collectimages.md) in the next section.

</br>

___

<table width="100%">
<tr><td><a href="./connectingcameras.md">^^^ Connecting cameras</td><td><a href="./collectimages.md">Collect images for training >>></td></tr>
</table>




