---
title: Remote MQTT trigger
layout: default
nav_order: 5
parent: Using VIAI
---
# Using the solution

## Triggering inspection remotely with an MQTT command

To remotelly trigger taking pictures and running inference on them, you can use MQTT to publish commands to the camera client.

The main use case for this is to have an external inspection station, which notices that an object is on the conveyor belt, using sensors. When the object to be inspected is in front of the camera, this external system can send an MQTT message to the VIAI Edge application to trigger the camera and visual inspection of the image.

Another use case is to have an external physical system with push buttons, to let human operators easily trigger taking an image and running inference. Pressing the button can send MQTT messages to control this application.

The utility listens for MQTT commands in topic: `viai/commands`. It publishes MQTT results on the topic: `viai/results`. Currently, the following MQTT payload commands have been implemented: `get_frame`, `exit` and `quit` (both exit and quit close the utility gracefully).

1. Start the utility in daemon mode, with both listening for commands over MQTT, as well as publishing the ML inference results in another MQTT topic:

    ```bash
    export ML_HOST=viai-model
    export MQTT_HOST=mosquitto

    python3 camera_client.py --protocol usb --address /dev/video0 --device_id 'usbcam' \
        --mode mqtt_sub --mqtt --mqtt_host ${MQTT_HOST} --sleep 0 --ml --ml_host ${ML_HOST}
    ```

    If everything goes well, the utility starts in daemon mode and outputs similar to:

    ```text
    2022-09-13 06:45:23,846 - root - INFO - Starting MQTT client. Publishing results to: viai/results
    Local network MQTT connected with result code 0
    Subscribing to MQTT topic: viai/commands
    MQTT subscription result code: (0, 1)
    ```

2. On a second console window, subscribe to the MQTT inference results.

    *Note:* this requires installing the mosquitto MQTT client on your laptop or running these commands on the VIAI Edge server:

    ```bash
    mosquitto_sub -h ${MQTT_HOST} -t viai/results
    ```

3. On a third console window, publish the trigger message to the VIAI Edge utility:

    ```bash
    mosquitto_pub -h ${MQTT_HOST}-t viai/commands -m get_frame
    ```

    If successful, your VIAI Edge utility window should display:

    ```text
    INFO:root:MQTT command received: get_frame
    INFO:root:{'predictionResult':...
    INFO:root:Transmitting ML inference results to local MQTT
    INFO:root:Local MQTT transmit complete
    ```

    and your mosquitto_sub window should display the ML inspection result payload:

    ```text
    {"predictionResult":...
    ...
    ```

4. Quit the utility by sending a quit message with:

    ```bash
    mosquitto_pub -h ${MQTT_HOST} -t viai/commands -m quit
    ```

    Which should close the utility on the VIAI Edge server and output:

    ```text
    INFO:root:Quit command received via MQTT..
    ```
