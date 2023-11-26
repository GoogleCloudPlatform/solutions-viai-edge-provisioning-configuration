---
title: No camera client
layout: default
nav_order: 1
parent: Other Topics
---
# Using the solution

## Using a camera and the VIAI model container without the camera client application

The camera integration app was built to ease the usage of typical industrial
cameras, with the VIAI inference container and an optional GCP backend.

However, if the camera integration app does not meet the specific customer
requirements for example for performance (FPS, bandwidth, latency) or features (specific camera protocol or ML inference results handling) - the camera and ML container can be used without the app.

Run on Setup Workstation
{: .label .label-blue}

1. Use the existing third-party camera integration to acquire images from the camera.

2. Transfer the images to GCS for VIAI model training. You can still use the rsync examples from this documentation.

3. Send the images using `HTTP POST` to the ML container.

    The URL would be 'http://`ip_address`:`port`/v1/visualInspection:predict'

    Where:

    * `ip_address` is the service IP of the running VIAI container
    * `port` is the first service port

    You can find both running the following in the VIAI Edge server

    ```bash
    kubectl -n ${NAMESPACE} get services
    ```

4. Create a base64 encoded JSON payload file from an image file

    ```bash
    cat img.png |base64 -w 0 > body
    ```

5. Edit the base64 encoded image file ‘body’, and add JSON formatting to the
beginning and end of the (long base64 encoded) line.

    Original ‘body’ contents example: iVBORw0KGgoAAA <br>
    New contents example: {"image_bytes":"iVBORw0KGgoAAA”}

    Note the {"image_bytes":" at the start of the single line content, and “} at the end. Save this edited JSON-formatted, base64 encoded single line file called ‘body’.

6. Post the body to the VIAI ML model using the curl command

    ```bash
    curl -v -X POST -H "Content-Type: application/json" -d @body http://ml-model:8602/v1/visualInspection:predict
    ```

    If successful, the output will be similar to:

    ```text
    {"predictionResult":{"annotationsGroups":[{"annotationSet":{"name":"projects…
    ```

7. Process the received POST response, which should contain the JSON-formatted ML inference results.
