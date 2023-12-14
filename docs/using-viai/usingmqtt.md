---
title: Inference to MQTT
layout: default
nav_order: 3
parent: Using VIAI
---
# Using the solution

## Streaming inference results to local MQTT for local actions

The solution supports streaming the ML inference results to a locally MQTT queue. For convenience, the VIAI Edge server runs a mosquitto broker container, which you can use to inform local systems of the visual inspection results.
The local systems can then for example inform human operators that a faulty object was detected or to control a robotic arm that pushes suspected faulty objects off the production line for human inspection.

To start publishing ML inference results to the VIAI Edge server-local MQTT topic, add the following switches to the camera app:

* `--mqtt` when set, enables publishing ML inference results JSON to an MQTT topic
* `--mqtt_host` the host address where the MQTT broker runs (LAN-side IP of VIAI Edge)
* `--mqtt_port` the MQTT broker service port. Default: 1883

To start live inference and publishing the inference results to a local MQTT topic, execute the following command and change the addresses to match your system:

Run on Edge Server
{: .label .label-green}

```bash
export ML_HOST=viai-model
export MQTT_HOST=mosquitto

python3 camera_client.py --protocol genicam --gentl /var/lib/viai/camera-config/FLIR_GenTL_Ubuntu_20_04_x86_64.cti \
  --cfg_write --cfg_write_file ./flir-ax5-recommended.cfg --device_id ax5  --mode continuous --ml --ml_host ${ML_HOST}
  --ml_port 8602 --mqtt --mqtt_host ${MQTT_HOST} --mqtt_port 1883
```
