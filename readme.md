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

scripts/provisioning-terraform.sh \
  -a \
  -g \
  -l "${VIAI_STORAGE_BUCKET_LOCATION}" \
  -p "${DEFAULT_PROJECT}" \
  -r "${DEFAULT_REGION}" \
  -z "${DEFAULT_ZONE}" \
  -m "${GOOGLE_CLOUD_DEFAULT_USER_EMAIL}" \
  -x

```

## Anthos Setup

### Create `anthos` VIAI application assets use `Artifacts Registry` and `Cloud Build`, and create a `.ISO` file for Anthos Bare Metal set up

```shell
# Generate Kubernete yaml files and scripts to installl required packages and drivers.
# Application container images are pushed to Artifacts Registry

export ANTHOS_SVC_ACCOUNT_KEY_PATH="$(pwd)/tmp/service-account-key.json"
export VIAI_SVC_ACCOUNT_KEY_PATH="$(pwd)/tmp/viai-camera-integration-client_service_account_key-service-account-key.json"
export CONTAINER_REPO_HOST="${DEFAULT_REGION}-docker.pkg.dev"
export CONTAINER_REG_NAME="${DEFAULT_REGION}-viai-applications"
export CONTAINER_BUILD_METHOD="GCP"
export K8S_RUNTIME="anthos"
export MEMBERSHIP="${K8S_RUNTIME}-server"
export REPO_TYPE="ArtifactRegistry"

bash ./scripts/0-generate-viai-application-assets.sh \
    -M "${CONTAINER_BUILD_METHOD}" \
    -v "${VIAI_SVC_ACCOUNT_KEY_PATH}" \
    -k "${ANTHOS_SVC_ACCOUNT_KEY_PATH}" \
    -m "${MEMBERSHIP}" \
    -H "${CONTAINER_REPO_HOST}" \
    -N "${CONTAINER_REG_NAME}" \
    -i "${K8S_RUNTIME}" \
    -Y "${REPO_TYPE}" \
    -b "main" \
    -l "<Camera Application Git URL>" \
    -p "${DEFAULT_PROJECT}"

```


### Generste Edge Server setup scripts

This script cresta VXLAN on the host and install Anthos.

```shell
export OUTPUT_FOLDER="<OUTPUT_FOLDER of previous step>"
export GOOGLE_CLOUD_DEFAULT_USER_EMAIL=my-user@my-org.com
export K8S_RUNTIME=anthos
export MEMBERSHIP="${K8S_RUNTIME}-server"
export DEFAULT_REGION=us-central1
export ANTHOS_SVC_ACCOUNT_KEY_PATH="$(pwd)/tmp/test-2-viai-abm.key"

bash ./scripts/1-generate-edge-server-assets.sh \
    -G "${ANTHOS_SVC_ACCOUNT_KEY_PATH}" \
    -A "${ANTHOS_SVC_ACCOUNT_KEY_PATH}" \
    -S "${ANTHOS_SVC_ACCOUNT_KEY_PATH}" \
    -C "${ANTHOS_SVC_ACCOUNT_KEY_PATH}" \
    -p "${DEFAULT_PROJECT}" \
    -k "${ANTHOS_SVC_ACCOUNT_KEY_PATH}" \
    -r "${DEFAULT_REGION}" \
    -m "${MEMBERSHIP}" \
    -o "${OUTPUT_FOLDER}" \
    -i "${K8S_RUNTIME}" \
    -u "${GOOGLE_CLOUD_DEFAULT_USER_EMAIL}"

```

### Generate Cloud-Init CIDATA .ISO File

```shell

export MEDIA_TYPE="USB"
export K8S_RUNTIME="anthos"

bash ./scripts/2-generate-media-file.sh \
    --edge-config-directory-path "${OUTPUT_FOLDER}" \
    --media-type "${MEDIA_TYPE}" \
    --k8s-runtime "${K8S_RUNTIME}"

```

### Notes

* The `provision-terraform.sh -a` command creates a Storage Bucket `gs://tf-state-${DEFAULT_PROJECT}/` to store Terraform state that is not managed by Terraform. This is intentionaly to ensure the state will be always available when create / update resources.

The Bucket will be deleted if you run `provision-terraform.sh -s "destroy"` to delete generated resources.
