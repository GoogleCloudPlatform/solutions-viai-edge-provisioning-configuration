# Visual Inspection AI Edge Solution document

## Required Roles to run Terraform

* BigQuery Data Editor
* Cloud Functions Admin
* Editor
* Project IAM Admin
* Pub/Sub Admin
* Source Repository Administrator

## Script Options

Below is a table of Long options and Short options mapping that are used in this solution. Please run `<script.sh> -h` or `<scrip.sh> --help` to see a full option list and description.


## Samples

### Provision Cloud Resources

```shell
# Provision Cloud Resources and a GCE Instance as Sandbox machine.
export DEFAULT_PROJECT=my-project
export DEFAULT_REGION=us-central1
export DEFAULT_ZONE=us-central1-a
export VIAI_STORAGE_BUCKET_LOCATION=US
export GOOGLE_CLOUD_DEFAULT_USER_EMAIL=my-user@my-org.com
export VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL=<VIAI Edge Camera Application source repository>
export VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH=<VIAI Edge Camera Application source branch>

scripts/provisioning-terraform.sh \
  -a \
  -g \
  -l "${VIAI_STORAGE_BUCKET_LOCATION}" \
  -p "${DEFAULT_PROJECT}" \
  -r "${DEFAULT_REGION}" \
  -z "${DEFAULT_ZONE}" \
  -m "${GOOGLE_CLOUD_DEFAULT_USER_EMAIL}" \
  —c "${VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL}" \
  —b "${VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH}" \
  -x


```

## Anthos Setup

### Create `anthos` VIAI application assets use `GCR` and `Cloud Build`, and create a `.ISO` file for Anthos Bare Metal set up

```shell
# Generate Kubernete yaml files and scripts to installl required packages and drivers.
export ANTHOS_SVC_ACCOUNT_KEY_PATH=$(pwd)/tmp/service-account-key.json
export CONTAINER_REPO_HOST="gcr.io"
export CONTAINER_BUILD_METHOD="GCP"
export K8S_RUNTIME="anthos"
export MEMBERSHIP=${K8S_RUNTIME}-server
export REPO_TYPE="GCR"
export VIAI_SVC_ACCOUNT_KEY_PATH=$(pwd)/tmp/viai-camera-integration-client_service_account_key-service-account-key.json

bash ./scripts/0-generate-viai-application-assets.sh \
    -M ${CONTAINER_BUILD_METHOD} \
    -v "${VIAI_SVC_ACCOUNT_KEY_PATH}" \
    -k "${ANTHOS_SVC_ACCOUNT_KEY_PATH}" \
    -m ${MEMBERSHIP} \
    -H "${CONTAINER_REPO_HOST}" \
    -i ${K8S_RUNTIME} \
    -Y ${REPO_TYPE} \
    -p "${DEFAULT_PROJECT}"

# Generate scripts to install and configure Anthos Bare Metal cluster with vxlan.
export OUTPUT_FOLDER="<OUTPUT_FOLDER of previous script>"
export ANTHOS_SVC_ACCOUNT_KEY_PATH=$(pwd)/tmp/service-account-key.json
export GOOGLE_CLOUD_DEFAULT_USER_EMAIL=my-user@my-org.com
export K8S_RUNTIME=anthos
export MEMBERSHIP=${K8S_RUNTIME}-server
export DEFAULT_REGION=us-central1

bash ./scripts/1-generate-edge-server-assets.sh \
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
    -u ${GOOGLE_CLOUD_DEFAULT_USER_EMAIL} 2>&1 | tee log-1.log

```

### Generate Cloud-Init CIDATA .ISO File

```shell

export MEDIA_TYPE="USB"
export K8S_RUNTIME="anthos"
bash ./scripts/2-generate-media-file.sh \
    --edge-config-directory-path ${OUTPUT_FOLDER} \
    --media-type ${MEDIA_TYPE} \
    --k8s-runtime ${K8S_RUNTIME}

```
