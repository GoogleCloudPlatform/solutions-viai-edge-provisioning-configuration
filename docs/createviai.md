# Deployment

## Creating VIAI Assets

<br>

Administrators or Google will perform this task. This procedure performs the following steps:

1. Clones the latest version of Visual Inspection AI Camera Application from a
source repository.
2. Uses Kaniko to build Visual Inspection AI Camera Application container images and push the image to the remote private container registry.
3. Pushes the required container images to a private repository.
4. Creates image pull secrets and Pub/Sub credential secrets.
5. Updates Kubernetes manifest files.

Follow the steps below to create the application assets:

Build the application and push the image to your container registry by running below scripts.

Note that the script pulls Visual Inspection AI Edge Application source codes from a source repository, which defaults to `https://source.developers.google.com/p/cloud-ce-shared-csr/r/MARKKU-viai-edge-camera-integration` . If you have another source repository, you must first authenticate to the source repository before running the script.

Review the env variables and update as needed:

```bash
export ANTHOS_SVC_ACCOUNT_KEY_PATH=$(pwd)/tmp/service-account-key.json
export CONTAINER_BUILD_METHOD="GCP"
export DEFAULT_PROJECT=<<YOUR GCP PROJECT>>
export DEFAULT_REGION=<<GCP REGION>>
export CONTAINER_REPO_HOST="${DEFAULT_REGION}-docker.pkg.dev"
export K8S_RUNTIME="anthos"
export MEMBERSHIP=${K8S_RUNTIME}-server
export REPO_TYPE="ArtifactRegistry"
export VIAI_SVC_ACCOUNT_KEY_PATH=$(pwd)/tmp/viai-camera-integration-client_service_account_key-service-account-key.json
export VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL="https://source.developers.google.com/p/cloud-ce-shared-csr/r/MARKKU-viai-edge-camera-integration"
export VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH="main"
```

Launch the script to generate the VIAI assets:

```bash
./scripts/0-generate-viai-application-assets.sh \
    -M ${CONTAINER_BUILD_METHOD} \
    -v "${VIAI_SVC_ACCOUNT_KEY_PATH}" \
    -k "${ANTHOS_SVC_ACCOUNT_KEY_PATH}" \
    -m "${MEMBERSHIP}" \
    -H "${CONTAINER_REPO_HOST}" \
    -i "${K8S_RUNTIME}" \
    -Y "${REPO_TYPE}" \
    -p "${DEFAULT_PROJECT}" \
    -l "${VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL}" \
    -b "${VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH}"
```

Where:

* `ANTHOS_SVC_ACCOUNT_KEY_PATH` The service account key file path for Anthos. If you follow the previous section to provision cloud resources, a key file was downloaded to `$(pwd)/tmp/service-account-key.json`

* `REPO_TYPE` Can be one of the following:
  * `Private` for a Private container registry
  * `GCR` for Google Cloud Container Registry
  * `ArtifactRegistry` for Google Cloud Artifact Registry.

* `CONTAINER_REPO_HOST` Required if `REPO_TYPE` is `Private`. If you use Container Registry, use the below table to specify a valid hostname:

| Visual Inspection AI Region | Hostname |
|-----------------------------|----------|
| us-central1                 | gcr.io   |
| europe-west4                | eu.gcr.io |


* `CONTAINER_REPO_USER` Required if `REPO_TYPE` is `Private`,  the username of private container registry.

* `CONTAINER_REPO_PASSWORD` Required if `REPO_TYPE` is `Private`,  the password  of private container registry.

* `CONTAINER_REPO_REG_NAME`
  * If `REPO_TYPE` is `Private`, the registry name of the Container Registry.
  * If `REPO_TYPE` is `GCR`, this value should equal to `${DEFAULT_PROJECT}`.

* `CONTAINER_BUILD_METHOD` Must be `GCP`, instruct the script to submit Visual Inspection AI Edge solution codes to `Cloud Build` to build the container image.

* `DEFAULT_PROJECT` the ID of the Google Cloud project to provision the resources to complete this installation.

* `DEFAULT_REGION` Default Google Cloud Region.

* `GOOGLE_CLOUD_DEFAULT_USER_EMAIL` User’s email. This user will be granted gateway RBAC and required roles to access Anthos Cluster. Will be ignored if `${GENERATE_ATTACH_CLUSTER_SCRIPT}` is `false`.

* `K8S_RUNTIME` Must be `anthos`.

* `MEMBERSHIP` Anthos membership name. This is the name that will be used in Anthos console to represent the edge server.

* `VIAI_SVC_ACCOUNT_KEY_PATH` VIAI service account key, The Terraform script will download the service account key to `./tmp/viai-camera-integration-client_service_account_key-service-account-key.json` folder.


After the script completes, you shoud see an output similar to this.<br>
__Important:__ Take note of the _output folder_ where the assets have been generated.

```text
  1.6.15: digest: sha256:abc6b06c4b65adca0d1330e6ef58f795c77c22a0229ba8e465014acfaab451b3 size: 946
  Push eclipse-mosquitto:1.6.15 to us-central1-docker.pkg.dev/airy-boulevard-397316/us-central1-viai-applications/eclipse-mosquitto:1.6.15
  [OK]: optional name of the membership register to Anthos value is defined: anthos-server
  Cleaning the authentication information...
  gcloud-config
  [Generating Assets] Completed.

  VIAI application assets have been generated at: /tmp/tmp.39xMkl1xDm
```

The _output folder_ has the following structure:

```text
  /tmp/tmp.39xMkl1xDm
  ├── kubernetes
  │   ├── mosquitto.yaml
  │   ├── namespace.yaml
  │   ├── secret_image_pull.yaml
  │   ├── secret_pubsub.yaml
  │   └── viai-camera-integration.yaml
  ├── scripts
  │   ├── 1-deploy-app.sh
  │   ├── common.sh
  │   ├── deploy-app.sh
  │   ├── gcp-anthos-attach-cluster.sh
  │   └── machine-install-prerequisites.sh
  └── service-account-key.json
```

Where:

* `kubernetes` folder containes the required kubernetes manifest files to deploy the VIAI application.

* `scripts` folder contains the required scripts to set up the edge server.

Verify if the Kubernetes manifest files and scripts are correctly generated. These scripts will be copied to the target server in later steps and executed there to provision the server.

If your environment will have multiple cameras, please [use this guide](./multiplecameras.md) to create assets for this particular case.

<br>

__Creating Kubernetes setup assets__

By default, the Anthos installation requires you to allocate IP addresses for Control Plane and Load Balancer.
It is out of the scope of this document to show How to design and manage IP addresses allocation, please refer to the [Anthos Network Requirements](https://cloud.google.com/anthos/clusters/docs/bare-metal/latest/concepts/network-reqs) and the [Set up Load Balancer](https://cloud.google.com/anthos/clusters/docs/bare-metal/latest/installing/load-balance) guides for details.

This is an example table for IP Addresses allocation:

| Variable name |  Use   |  Sample IP address |
|---------------|--------|--------------------|
| CP_VIP   | Control Plane VIP. <br> You must use the server's host OS primary NIC IP. <br> Must be configured over DHCP manual allocation with the <br> correct MAC address of the first NIC you choose. | 192.168.1.21 <br> (must be the same IP as the server host OS primary IP) |
| LB_CP_VIP | The destination IP address to be used for traffic sent <br> to the Kubernetes control plane. <br> These IPs must NOT be reachable during Anthos setup. <br> Must be in the same subnet as CP_VIP. | 192.168.1.22 |
| INGRESS_VIP | The IP address to be used for Services behind the <br> load balancer for ingress traffic. <br> This IP must NOT be reachaeble during Anthos setup. <br> Must be the first IP address of LB_ADDRESS_RANGE. <br> Must be in the same subnet as CP_VIP. | 192.168.1.23 |
| LB_ADDRESS_RANGE | One IP range of contiguous IP addresses  (minimum 2 IPs but 4 IPs is recommended) <br> These IPs must NOT be reacheable during Anthos setup. | 192.168.1.23-192.168.1.26 |


<br>

Once you have allocated the required IP addresses, run the scripts below to generate the Kubernetes set up assets.


_Note:_ If you used the `-x` flag in the [previous step](./provisiongcp.md) to create a sandbox machine, the Terraform script will create a GCE VM with the IP address `10.128.0.2`. The suggested IPs in this particular case woul be:

| Variable | IP |
|----------|----|
| CP_VIP | 10.128.0.2 |
| LB_CP_VIP | 10.128.0.3 |
| INGRESS_VIP | 10.128.0.4 |
| LB_ADDRESS_RANGE | 10.128.0.4-10.128.0.7 |

<br>


Review and modify the environment variables for your environment:

```bash
export OUTPUT_FOLDER=<OUTPUT FOLDER noted on previous step>
export CP_VIP=192.168.1.21
export LB_CP_VIP=192.168.1.22
export INGRESS_VIP=192.168.1.23
export LB_ADDRESS_RANGE=192.168.1.23-192.168.1.27
```

Then, run:

```bash
./scripts/1-generate-edge-server-assets.sh \
    -G $(pwd)/tmp/service-account-key.json \
    -A $(pwd)/tmp/service-account-key.json \
    -S $(pwd)/tmp/service-account-key.json \
    -C $(pwd)/tmp/service-account-key.json \
    -p ${DEFAULT_PROJECT} \
    -k  $(pwd)/tmp/service-account-key.json \
    -r ${DEFAULT_REGION} \
    -m ${MEMBERSHIP} \
    -o ${OUTPUT_FOLDER} \
    -i ${K8S_RUNTIME} \
    -x \
    -R ${LB_ADDRESS_RANGE} \
    -V ${CP_VIP} \
    -I ${INGRESS_VIP} \
    -L ${LB_CP_VIP} \
    -u ${GOOGLE_CLOUD_DEFAULT_USER_EMAIL} 2>&1 | tee log-1.log
```

Where:

* `-x` Use physical IP addresses.
* `DEFAULT_PROJECT` Google Cloud Project name.
* `DEFAULT_REGION` Default Google Cloud region.
* `GOOGLE_CLOUD_DEFAULT_USER_EMAIL` User’s email. This user will be granted gateway RBAC and required roles to access Anthos Cluster. Will be ignored if `${GENERATE_ATTACH_CLUSTER_SCRIPT}` is `false`
* `K8S_RUNTIME` Kubernetes runtime, must be `anthos`
* `MEMBERSHIP` Anthos Membership name. This is the name that will be registered to Anthos to identify your edge server.
* `OUTPUT_FOLDER` VIAI Application assets folder path, usually is the output of the [previous step](./createviai.md#creating-viai-assets).

You can also use the `-h` flag to display all the possible options available.

This script
* Checks if the specified runtime folder exists, the path to the specific Kubernetes runtime should be `“${VIAI_PROVISIONING_FOLDER}"/edge-server/<RUNTIME>` (runtime is `anthos`)
* Passes input arguments to the `generate-script.sh` script in the runtime folder to generate additional required scripts to set up the edge server, this includes:
  * Generate scripts to install required packages, such as NVIDIA GPU Driver, gcloud command-line tool, docker…etc.
  * Update template files with specified environment variables.


After the script runs, the console will show details about the asset creation. All assets created are stored in the `$OUTPUT_PATH` folder.

```text
  Copying Anthos Bare Metal template file...
  Copy dependecies installation scripts...
  USERS_EMAILS=admin@junholee.altostrat.com
  Node setup scripts have been generated at /tmp/tmp.39xMkl1xDm/edge-server
  ```

  The `$OUTPUT_PATH` will have a structure similar to this:

```text
  /tmp/tmp.39xMkl1xDm/edge-server
  ├── anthos-service-account-key.json
  ├── bmctl-physical-template.yaml
  ├── cloud-ops-account-key.json
  ├── config-section.toml
  ├── gcr-service-account-key.json
  ├── gke-connect-angent-account-key.json
  ├── gke-connect-register-account-key.json
  ├── machine-install-prerequisites.sh
  └── node-setup.sh
```



Yu can continue to the next step, deploy the VIAI Edge solution in the edge server.

</br>

___

<table width="100%">
<tr><td><a href="./deployment.md">^^^ Deployment of the solution</td><td><a href="./deployedge.md">Deploy VIAI in the edge server >>></td></tr>
</table>
