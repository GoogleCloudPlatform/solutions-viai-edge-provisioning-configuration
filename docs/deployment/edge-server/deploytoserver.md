---
title: Deploy to Physical Server
layout: default
parent: Deploy to Server
grand_parent: Deployment
nav_order: 1
---
# Deployment

## Deploy the solution to a physical dedicated server

<br>

__Downloading the OS images and writing them to USB drives__

_Warning:_ This procedure will wipe all the data that is currently in both USB drives.

The following steps should be run on the _setup machine_ (your Linux or macOS):

1. Switch to the current project:

    ```bash
    gcloud config set project $DEFAULT_PROJECT
    ```

2. Plug the 4GB (min) flash drive into the setup machine.

3. Download the OS installer ISO image:

    ```bash
    cd $VIAI_PROVISIONING_FOLDER
    ./scripts/download-os-images.sh
    ```

    The output should be similar to the following:

    ```text
    [...]
    OS image downloaded and verified: viai-provisioning-configuration/ubuntu-20.04.6-live-server-amd64.iso
    ```

    Take note of the OS image path that the script produces.

4. Write the OS installer image file on the larger (min 4GB USB drive)

    You can use an image flash app like [Balena Etcher](https://etcher.balena.io/) or any of the following options, depending on the OS of the setup machine:

    __On Linux__

    ```text
    sudo dd bs=4M if=[PATH_TO_OS_INSTALLER_ISO] of=[USB_FLASH_DRIVE] conv=fdatasync status=progress
    ```

    __On macOS__

    Use `diskutil` to list the devices attached and select the device ID, for example `/dev/disk4`. Then, run the following:

    ```bash
    INSTALLER_CONFIG_DATA_USB_FLASH_DRIVE=/dev/<DEVICE ID>

    diskutil unmountDisk $INSTALLER_CONFIG_DATA_USB_FLASH_DRIVE

    sudo dd bs=4m if="${VIAI_INSTALLER_CONFIGURATION_DATA_ISO_FILE_PATH}" of=$INSTALLER_CONFIG_DATA_USB_FLASH_DRIVE

    sync

    sudo diskutil eject $INSTALLER_CONFIG_DATA_USB_FLASH_DRIVE
    ```

    Where:

    * `PATH_TO_OS_INSTALLER_ISO` path to the OS installer ISO, noted earlier.

    * `USB_FLASH_DRIVE` path to the raw device representing the USB flash drive where you flash the OS installer. You can use `lsblk` (on Linux) or `diskutil list` (on macOS) to get this value.
    Refer to this [Raspberry Pi guide document](https://www.raspberrypi.org/documentation/computers/getting-started.html) for a useful reference. On macOS, use `rdisk` instead of `disk` to speed up the copy when running the `dd` command.

    Unplug the USB flash drive.

__Creating hardware installation assets__

This step will generate a cloud-init CIDATA ISO file which will then be flashed to a second USB drive. <br>

The server will boot later from the two USB drives; one will contain the operating system installation image (prepared in the steps before), and the second, generated in this step, will contain cloud-init deployment automation files.

Run this commands to create the .ISO file:

```bash
export MEDIA_TYPE="USB"

./scripts/2-generate-media-file.sh \
  -d ${OUTPUT_FOLDER} \
  -t ${MEDIA_TYPE} \
  -i ${K8S_RUNTIME}
```

Where:

* `MEDIA_TYPE` must be `USB`

After the script runs, the console will show details about the asset creation. All assets created are stored in the `$OUTPUT_PATH` folder.

```text
242 extents written (0 MB)
Deleting the temporary working directory (/tmp/tmp.8He7ET4VIC)...
Results saved in the temporary working directory: /tmp/cloud-init-output
CIDATA ISO file created successfully, folder path: /tmp/tmp.dc9KQE1Xa8 , file name: cloud-init-datasource.iso
Cleaning up...
```

Save the path to the ISO image that was just generated in an environment variable:

```bash
export VIAI_INSTALLER_CONFIGURATION_DATA_ISO_FILE_PATH="${OUTPUT_PATH}/cloud-init-datasource.iso"
```

Flash the installer configuration data to the USB flash drive:

You can use again an application like [Balena Etcher](https://etcher.balena.io/) to write the `cloud-init-datasource.iso` on the second USB flash drive.

Alternatively, you can use the commands below, depending on your platform:

__On Linux__

```bash
sudo dd bs=4M if="${VIAI_INSTALLER_CONFIGURATION_DATA_ISO_FILE_PATH}" of=[INSTALLER_CONFIG_DATA_USB_FLASH_DRIVE] conv=fdatasync status=progress
```

__On macOS__

Use `diskutil list` to list the devices attached and select the device ID, for example `/dev/disk4`. Then, run the following:

```bash
INSTALLER_CONFIG_DATA_USB_FLASH_DRIVE=/dev/<DEVICE ID>

diskutil unmountDisk $INSTALLER_CONFIG_DATA_USB_FLASH_DRIVE

sudo dd bs=4m if="${VIAI_INSTALLER_CONFIGURATION_DATA_ISO_FILE_PATH}" of=$INSTALLER_CONFIG_DATA_USB_FLASH_DRIVE

sync

sudo diskutil eject $INSTALLER_CONFIG_DATA_USB_FLASH_DRIVE
```

Where:

* `INSTALLER_CONFIG_DATA_USB_FLASH_DRIVE` path to the raw device representing the USB flash drive where you flash the OS installer. You can use `lsblk` (on Linux) or `diskutil list` (on macOS) to get this value.
Refer to this [Raspberry Pi guide document](https://www.raspberrypi.org/documentation/computers/getting-started.html) for a useful reference. On macOS, use `rdisk` instead of `disk` to speed up the copy when running the `dd` command.

Unplug the USB flash drive.

You can now continue to physically setup the edge server.
