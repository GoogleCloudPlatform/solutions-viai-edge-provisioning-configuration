# Deployment

## Creating VIAI Assets for multiple camera applications

<br>

If your edge server will connect to multiple cameras, you’ll need multiple camera application PODs. You can use optional arguments to generate Kubernetes deployment for multiple cameras.

```bash
./scripts/0-generate-viai-application-assets.sh \
    -M "${CONTAINER_BUILD_METHOD}" \
    -v "${VIAI_SVC_ACCOUNT_KEY_PATH}" \
    -k "${ANTHOS_SVC_ACCOUNT_KEY_PATH}" \
    -m "${MEMBERSHIP}" \
    -H "${CONTAINER_REPO_HOST}" \
    -i "${K8S_RUNTIME}" \
    -Y "${REPO_TYPE}" \
    -p "${DEFAULT_PROJECT}" \
    -N "${CONTAINER_REG_NAME}" \
    -r "1-3" \ # Camera Id: camera-1, camera-2, camera-3
    -x \       # DO not rebuild container image
    -t "gcr.io/your-project/your-image:tag" # Container image location
```

Where:

* `-r` Numeric IDs separated by “-”. For example, `-r “1-3”` tells the script to generate camera applications with ID of viai-camera-integration-1, viai-camera-integration-2 and viai-camera-integration-3.

* `-x` If this flag is set, the script will only generate Camera application deployment yaml files. It will _NOT_ recreate `ImagePullSecrets` and other application assets.

* `-t` Tell the script to use the image url instead of recreating the camera application container image. `-x` _MUST_ be set for `-t` to work.


</br>

___

<table width="100%">
<tr><td><a href="./deployment.md">^^^ Deployment of the solution</td><td><a href="./deployedge.md">Deploy VIAI in the Edge server >>></td></tr>
</table>
