# Connecting the cameras

## Connecting Genicam cameras

<br>

This method is for cameras that support the [Genicam standard](https://www.emva.org/standards-technology/genicam/).

Follow these steps:

Ensure that the Genicam camera is connected to the same subnet as your host computer, using a gigabit ethernet PoE (Power over Ethernet) cable.

Print the supported command line switches:

```bash
kubectl exec -it viai-camera-integration -n ${NAMESPACE} -- /bin/bash -c 'python3 camera_client.py --help'
```

Output will be similar to the following:
```
usage: camera_client.py [-h] [--log LOG] --device_id DEVICE_ID
                            [--device_no DEVICE_NO] [--gentl GENTL]
                            [--mode {none,single,continuous}] [--model MODEL]
                            [--labels LABELS] [--top_k TOP_K]
```

To communicate with the camera, you need to have its GenTL producer file, with a `.cti` file ending, and the file should be compiled for Linux x86-64. The repository contains an example GenTL producer file for FLIR cameras, for both macOS and Ubuntu 20.04 which is the base OS of the reference server. To use your camera’s GenTL producer file, place it in a directory on the server that the docker image can access.

The container that runs the camera integration utility is called `viai-camera-integration-operations`.
It is located inside the pod called `viai-camera-integration`.

You can see this by running the following command:
```bash
kubectl describe pod viai-camera-integration -n ${NAMESPACE}
```

The camera utility container has volumes mounted on it, which are shared with the server’s host operating system:

* Mountpoint inside the container: `/var/lib/viai/camera-config`
    * Used to store camera configuration files, and GenTL producer .cti files
* Mountpoint inside the container: `/var/lib/viai/camera-data`
    * Used to write imager array data from the camera, in images, or raw binary files

On the host OS side, microk8s mounts those 2 shared volumes in dynamically allocated paths. To find the path of the shared volumes on the Ubuntu host side, run:

```bash
kubectl get pv -n ${NAMESPACE}
```

Which should output something similar to:

```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                               STORAGECLASS        REASON   AGE
pvc-b0a2e5ff-9414-4736-aba3-ad6b92597d7e   20Gi       RWX            Delete           Bound    container-registry/registry-claim   microk8s-hostpath            5h55m
pvc-826b7dce-0de9-48a7-bfea-fbe20237b779   100Mi      RWO            Delete           Bound    default/viai-camera-config          microk8s-hostpath            24m
pvc-61dba069-0f44-42ee-a326-80277d53ec2f   10Gi       RWO            Delete           Bound    default/viai-camera-data            microk8s-hostpath            24m
```

You can then use the `pvc-` identifiers to see the actual path on the host OS side (use your own `pvc-`):

```bash
kubectl describe pv pvc-826b7dce-0de9-48a7-bfea-fbe20237b779
```

The command should output similar to this, where the shared volume path is the attribute `Path`:

```
Name:            pvc-826b7dce-0de9-48a7-bfea-fbe20237b779
Labels:          <none>
Annotations:     hostPathProvisionerIdentity: localhost
                pv.kubernetes.io/provisioned-by: microk8s.io/hostpath
Finalizers:      [kubernetes.io/pv-protection]
StorageClass:    microk8s-hostpath
Status:          Bound
Claim:           default/viai-camera-config
Reclaim Policy:  Delete
Access Modes:    RWO
VolumeMode:      Filesystem
Capacity:        100Mi
Node Affinity:   <none>
Message:  
Source:
    Type:          HostPath (bare host directory volume)
    Path:          /var/snap/microk8s/common/default-storage/default-viai-camera-config-pvc-826b7dce-0de9-48a7-bfea-fbe20237b779
    HostPathType:
Events:          <none>
```

To view any files on one of the shared volumes, run the following on the host OS side - replacing the path with your path from the above command output:

```bash
ls -l /var/snap/microk8s/common/default-storage/default-viai-camera-config-pvc-bd25e2f7-9e77-412b-9553-e07ce170e2f1
```

<br>

__Transferring your camera GenTL producer file to the system__

This is applicable to cameras that use the Genicam protocol stack. Each camera has a GenTL producer file, compiled to the target architecture. In the case of the reference server, the architecture is Ubuntu Linux x86-64. To interface with a Genicam-based camera on this server, you need to get the GenTL producer `.cti` file compiled for Linux x86-64.

Once you have the file, you need to transfer it to the shared volume `viai-camera-config`, using the commands from the previous section to identify the host OS path for that volume/directory. It should be under `/var/snap/microk8s/common/default-storage/<dynamic path>` on the server.

Transfer the GenTL producer file to the shared volume with the following steps:

1. On your host (laptop, etc where you have the GenTL producer file for your camera), transfer the file to the server host OS, to the viai-admin user’s home directory

```bash
scp your-camera.cti viai-admin@<viai-host-ip>:
```

2. Login to the server

```bash
ssh viai-admin@<viai-host-ip>
```

3. Copy th eGenTL file to the shared volume

```bash
cp your-camera.cti <viai-camera-config volume path from the section above>
```

4. Open a shell to the camera utility container

```bash
kubectl exec -it viai-camera-integration  -n ${NAMESPACE} -- /bin/bash
```

5. Confirm that the container sees the new GenTL file in the shared volume

```bash
ls -l /var/lib/viai/camera-config/
```

The output should be similar to this:

```
-rw------ 1 root root 29 Oct 13 10:11 my-camera-gentl-ubuntu-x86-64.cti
```

<br>

__Scanning for Genicam cameras__

Now that you have the GenTL producer file, you can scan for Genicam-based cameras on the local network segment.

1. Connect your camera to the same LAN segment as the server, using its Power over Ethernet (PoE) cable with a LAN cable from the same switch as the server. Ensure that the camera is powered on.

2. Inside the container shell (if you exited the container shell, you can reconnect using the command in Step 4 in the previous section), run the following command to try scan for camera(s) that are compatible with the Genicam GenTL producer file that you are using

```bash
python3 camera_client.py --protocol genicam --scan
```

The output should be similar to this:

```
Discovering Genicam cameras on the network..
Genicam cameras found: [{'access_status': 1, 'display_name': 'FLIR Systems AB', 'id_': '00111C0242D4_C0A8011F_FFFFFF00_C0A80101', 'model': 'FLIR AX5', 'parent': <genicam.gentl.Interface; proxy of <Swig Object of type 'std::shared_ptr< GenTLCpp::TLInterface > *' at 0x7fc4b54c9b70> >, 'serial_number': '62501484', 'tl_type': 'GEV', 'user_defined_name': '', 'vendor': 'FLIR Systems AB', 'version': 'Version 1.0  (02.05.15)'}]
```

    In the above example, you can see that 1 camera was found, and the model is a FLIR AX5. If your system can see multiple cameras, you can select which camera to connect to, by using the `--address` switch, counting up from zero. Meaning that if the command lists 2 cameras for example, the first listed camera is `--address 0` and the second camera is `--address 1`. The VIAI Edge solution can currently only connect to one camera at a time.

<br>

__Connecting to the camera and reading its runtime configuration__

In this section you will connect to the camera, read its current runtime configuration (GenTL node tree), and output it to a configuration file that you can edit. Later on, you can write the edited, desired configurations back to the camera.

Here, replace the value of `--device_id` with an arbitrary label that you wish to give this camera. For example: `site1_cam1`.

The label will be used in the data filenames written from that camera. And point the `--gen_tl` parameter’s value to the `.cti` file that you transferred to the shared volume in the previous sections. The mode switch `--mode none` instructs the utility not to take any images with the camera.

1. Query the camera configurations and output them to a file (replace the `device_id` and `getnl` path with your own values)

```bash
python3 camera_client.py --protocol genicam --address 0 --device_id cam1 \
    --gentl /var/lib/viai/camera-config/<your-camera>.cti --mode none \
    --cfg_read --cfg_read_file /var/lib/viai/camera-config/current.cfg
```

The output should look similar to this:

```
Cameras found: 1
(id_='00111C0242D4_C0A80019_FFFFFF00_C0A80001', vendor='FLIR Systems AB', model='FLIR AX5', tl_type='GEV', user_defined_name=None, serial_number='62501484', version='Version 1.0  (02.05.15)')
Querying camera runtime configs and saving to: /var/lib/viai/camera-config/current.cfg
Closing camera connection and exiting
```

2. Verify the generated camera configuration file

```bash
head -5 /var/lib/viai/camera-config/current.cfg
```

The output should be similar to this:

```
AcquisitionFrameCount = 1
AcquisitionMode = 'Continuous'
AtmTaoInternal = 8192
AtmTempInternal = 2200
AtmosphericTemperature = 295.15
```

At this point, the camera is connected and ready to use. You can start to [Collect images for training](./collectimages.md) in the next section.

</br>

Optionally, you can continue reading to understand how to manage the configuration of a Genicam camera:

__Managing the configuration of Genicam cameras__

The VIAI Edge utility supports reading and writing camera runtime configurations for Genicam and USB cameras.

* Query the camera's current runtime configurations and output them to an editable text file (replace `device_id` and `gentl` path with your own values)

```bash
python3 camera_client.py --protocol genicam --address 0 --device_id cam1 --gentl <your camera gentl>.cti \
    --mode none  --cfg_read --cfg_read_file /var/lib/viai/camera-config/current.cfg
```

* Verify the generated camera configuration file

```bash
head -5 /var/lib/viai/camera-config/current.cfg
```

The output should be similar to:

```
AcquisitionFrameCount = 1
AcquisitionMode = 'Continuous'
AtmTaoInternal = 8192
AtmTempInternal = 2200
AtmosphericTemperature = 295.15
```

* To change a configuration parameter value, edit the generated configuration file with your favorite editor

```bash
vi /var/lib/viai/camera-config/current.cfg
```

* Write the updated configurations back to the camera

```bash
python3 camera_client.py --protocol genicam --address 0 --device_id cam1 --gentl <your camera gentl>.cti \
    --mode none  --cfg_write --cfg_write_file /var/lib/viai/camera-config/current.cfg
```

The output should be similar to:

```
2022-09-13 02:52:14,755 - root - INFO - Reading config from input file: /var/lib/viai/camera-config/current.cfg
INFO:root:Writing config to the camera: Width = 640
...
```


___

<table width="100%">
<tr><td><a href="./connectingcameras.md">^^^ Connecting cameras</td><td><a href="./collectimages.md">Collect images for training >>></td></tr>
</table>




