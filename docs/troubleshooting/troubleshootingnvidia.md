---
title: NVIDIA GPU
layout: default
nav_order: 6
parent: Troubleshooting
---
# Troubleshooting

## Troubleshooting NVIDIA GPU

<br>

Visual Inspection AI requires a supported NVIDIA GPU model to run. Check the status of the NVIDIA card and drivers.

Run on Edge Server
{: .label .label-green}

1. Run the following command to check the Ubuntu drivers’ status for NVIDIA:

    ```bash
    ubuntu-drivers devices
    ```

    The command should output similar to:

    ```text
    == /sys/devices/pci0000:00/0000:00:01.0/0000:01:00.0 ==
    modalias : pci:v000010DEd00001E82sv00001043sd00008674bc03sc00i00
    vendor   : NVIDIA Corporation
    model    : TU104 [GeForce RTX 2080]
    manual_install: True
    driver   : nvidia-driver-460-server - distro non-free
    driver   : nvidia-driver-418-server - distro non-free
    driver   : nvidia-driver-450-server - distro non-free
    driver   : nvidia-driver-460 - distro non-free
    driver   : nvidia-driver-470 - distro non-free recommended
    driver   : nvidia-driver-470-server - distro non-free
    driver   : xserver-xorg-video-nouveau - distro free builtin
    ```

2. Run the following command to check the loaded NVIDIA driver version:

    ```bash
    nvidia-detector
    ```

    The output is similar to:

    ```text
    nvidia-driver-495
    ```

3. Run the following command to check that the NVIDIA GPU is visible to the system:

    ```bash
    prime-select query
    ```

    The command should output:

    ```text
    nvidia
    ```

    If the command outputs something different, for example 'intel', execute the following command to try to switch the system to use NVIDIA:

    ```bash
    prime-select nvidia
    ```

4. Run the following command to query the NVIDIA card and its driver status:

    ```bash
    nvidia-smi
    ```

    If successful, the output should be similar to this:

    ```text
    +-----------------------------------------------------------------------------+
    | NVIDIA-SMI 470.82.01    Driver Version: 470.82.01    CUDA Version: 11.4     |
    |-------------------------------+----------------------+----------------------+
    | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
    | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
    |                               |                      |               MIG M. |
    |===============================+======================+======================|
    |   0  NVIDIA GeForce ...  Off  | 00000000:01:00.0 Off |                  N/A |
    | 20%   30C    P8    17W / 215W |      0MiB /  7982MiB |      0%      Default |
    |                               |                      |                  N/A |
    +-------------------------------+----------------------+----------------------+

    +-----------------------------------------------------------------------------+
    | Processes:                                                                  |
    |  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
    |        ID   ID                                                   Usage      |
    |=============================================================================|
    |  No running processes found                                                 |
    +-----------------------------------------------------------------------------+
    ```
