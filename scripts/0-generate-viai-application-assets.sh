#!/usr/bin/env sh

# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o nounset
set -o errexit

# shellcheck disable=SC1094
. scripts/common.sh

# Doesn't follow symlinks, but it's likely expected for most users
SCRIPT_BASENAME="$(basename "${0}")"

ANTHOS_MEMBERSHIP_NAME_DESCRIPTION="name of the memnership register to Anthos"
ANTHOS_SERVICE_ACCOUNT_EMAIL_DESCRIPTION="email of Anthos set up service account"
ANTHOS_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION="path of the anthos service account key file"
CAMERA_APPLICATION_CONTAIMER_IMAGE_URL_DESCRIPTION="Camera application container registry location. ex, gcr.io/my-project/my-image:latest"
CAMERA_ID_RANGE_DESCRIPTION="Numeric id range of cameras, for example, 3-5 gives camera id from camera-03...to camera-05"
CONTAINER_IMAGE_BUILD_METHOD_DESCRIPTION="method of building container images, can be [GCP] or [KANIKO]."
CONTAINER_REPO_HOST_DESCRIPTION="private container repo host name, ex, repo.private.com"
CONTAINER_REPO_USERNAME_DESCRIPTION="private container repo user name"
CONTAINER_REPO_PASSWORD_DESCRIPTION="passowrd of the private container repo user"
CONTAINER_REPO_REPOSITORY_NAME_DESCRIPTION="name of the container repo registry. For GCR, this can be ignored. For Artifacts Registry, this defaults to <CLOUD-REGION>-viai-applications"
GENERATE_YAML_ONLY_DESCRIPTION="Only generate application YAML files only."
GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION="name of the default Google Cloud Project to use"
K8S_RUNTIME_DESCRIPTION="name of kubernetes runtime."
REPO_TYPE_DESCRIPTION="Container Registry type, can be [GCR] or [Private]"
USER_EMAILS_DESCRIPTION="email addresses to grant cluster RBAC roles, split by common, for example, [user1@domain.com,user2.domain.com]"
VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL_DESCRIPTION="the url of VIAI Camera application source repository"
VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH_DESCRIPTION="the branch name of VIAI Camera application source"
VIAI_CLIENT_INTEGRATION_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION="path of the VIAI integration service account key file"

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script initializes the environment for Terraform, and runs it. The script will always run terraform init and terraform validate before any subcommand you specify."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -t $(is_linux && echo "| --camera-container-image-location"): ${CAMERA_APPLICATION_CONTAIMER_IMAGE_URL_DESCRIPTION}"
  echo "  -r $(is_linux && echo "| --camera-id-range"): ${CAMERA_ID_RANGE_DESCRIPTION}"
  echo "  -M $(is_linux && echo "| --container-image-build-method"): ${CONTAINER_IMAGE_BUILD_METHOD_DESCRIPTION}"
  echo "  -H $(is_linux && echo "| --container-repo-host"): ${CONTAINER_REPO_HOST_DESCRIPTION}"
  echo "  -W $(is_linux && echo "| --container-repo-password"): ${CONTAINER_REPO_PASSWORD_DESCRIPTION}"
  echo "  -N $(is_linux && echo "| --container-repo-reg-name"): ${CONTAINER_REPO_REPOSITORY_NAME_DESCRIPTION}"
  echo "  -U $(is_linux && echo "| --container-repo-user"): ${CONTAINER_REPO_USERNAME_DESCRIPTION}"
  echo "  -p $(is_linux && echo "| --default-project"): ${GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION}"
  echo "  -x $(is_linux && echo "| --yaml-files-only"): ${GENERATE_YAML_ONLY_DESCRIPTION}"
  echo "  -b $(is_linux && echo "| --git-repo-branch"): ${VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH_DESCRIPTION}"
  echo "  -l $(is_linux && echo "| --git-repo-url"): ${VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL_DESCRIPTION}"
  echo "  -i $(is_linux && echo "| --k8s-runtime"): ${K8S_RUNTIME_DESCRIPTION}"
  echo "  -m $(is_linux && echo "| --membership"): ${ANTHOS_MEMBERSHIP_NAME_DESCRIPTION}"
  echo "  -Y $(is_linux && echo "| --repo-type"): ${REPO_TYPE_DESCRIPTION}"
  echo "  -e $(is_linux && echo "| --service-account-email"): ${ANTHOS_SERVICE_ACCOUNT_EMAIL_DESCRIPTION}"
  echo "  -k $(is_linux && echo "| --service-account-key-path"): ${ANTHOS_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION}"
  echo "  -u $(is_linux && echo "| --users"): ${USER_EMAILS_DESCRIPTION}"
  echo "  -v $(is_linux && echo "| --viai-account-key-path"): ${VIAI_CLIENT_INTEGRATION_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,service-account-key-path:,camera-container-image-location:,container-image-build-method:,container-repo-host:,container-repo-password:,container-repo-reg-name:,container-repo-user:,default-project:,git-repo-url:,git-repo-branch:,input-path:,k8s-runtime:,membership:,output-path:,repo-type:,viai-account-key-path:,service-account-email:,yaml-files-only"
SHORT_OPTIONS="hH:M:N:U:W:Y:b:e:i:k:l:m:p:r:t:v:x"

ANTHOS_MEMBERSHIP_NAME=
ANTHOS_SERVICE_ACCOUNT_KEY_PATH=
ANTHOS_SERVICE_ACCOUNT_EMAIL=
CAMERA_APPLICATION_CONTAIMER_IMAGE_URL=
CAMERA_ID_RANGE=
CONTAINER_IMAGE_BUILD_METHOD=
CONTAINER_REPO_HOST=""
CONTAINER_REPO_USERNAME=""
CONTAINER_REPO_PASSWORD=""
CONTAINER_REPO_REPOSITORY_NAME=""
CONTAINER_REPO_TYPE=""
GENERATE_YAML_ONLY="false"
GOOGLE_CLOUD_PROJECT=
K8S_RUNTIME=
VIAI_CAMERA_APP_IMAGE_TAG=
VIAI_CLIENT_INTEGRATION_SERVICE_ACCOUNT_KEY_PATH=
VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL=https://github.com/GoogleCloudPlatform/solutions-viai-edge-camera-integration
VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH=main

# BSD getopt (bundled in MacOS) doesn't support long options, and has different parameters than GNU getopt
if is_linux; then
  TEMP="$(getopt -o "${SHORT_OPTIONS}" --long "${LONG_OPTIONS}" -n "${SCRIPT_BASENAME}" -- "$@")"
elif is_macos; then
  TEMP="$(getopt "${SHORT_OPTIONS} --" "$@")"
  echo "WARNING: Long command line options are not supported on this system."
fi
RET_CODE=$?
if [ ! ${RET_CODE} ]; then
  echo "Error while evaluating command options. Terminating..."
  # Ignoring because those are defined in common.sh, and don't need quotes
  # shellcheck disable=SC2086
  exit ${ERR_ARGUMENT_EVAL_ERROR}
fi
eval set -- "${TEMP}"

while true; do
  case "${1}" in
  -t | --camera-container-image-location)
    CAMERA_APPLICATION_CONTAIMER_IMAGE_URL="${2}"
    shift 2
    ;;
  -r | --camera-id-range)
    CAMERA_ID_RANGE="${2}"
    shift 2
    ;;
  -M | --container-image-build-method)
    CONTAINER_IMAGE_BUILD_METHOD="${2}"
    shift 2
    ;;
  -N | --container-repo-reg-name)
    CONTAINER_REPO_REPOSITORY_NAME="${2}"
    shift 2
    ;;
  -H | --container-repo-host)
    CONTAINER_REPO_HOST="${2}"
    shift 2
    ;;
  -U | --container-repo-user)
    CONTAINER_REPO_USERNAME="${2}"
    shift 2
    ;;
  -W | --container-repo-password)
    CONTAINER_REPO_PASSWORD="${2}"
    shift 2
    ;;
  -p | --default-project)
    GOOGLE_CLOUD_PROJECT="${2}"
    shift 2
    ;;
  -x | --yaml-files-only)
    GENERATE_YAML_ONLY="true"
    shift
    ;;
  -b | --git-repo-branch)
    VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH="${2}"
    shift 2
    ;;
  -l | --git-repo-url)
    VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL="${2}"
    shift 2
    ;;
  -i | --k8s-runtime)
    K8S_RUNTIME="${2}"
    shift 2
    ;;
  -m | --membership)
    ANTHOS_MEMBERSHIP_NAME="${2}"
    shift 2
    ;;
  -Y | --repo-type)
    CONTAINER_REPO_TYPE="${2}"
    shift 2
    ;;
  -e | --service-account-email)
    ANTHOS_SERVICE_ACCOUNT_EMAIL="${2}"
    shift 2
    ;;
  -k | --service-account-key-path)
    ANTHOS_SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  -v | --viai-account-key-path)
    VIAI_CLIENT_INTEGRATION_SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  --)
    shift
    break
    ;;
  -h | --help | *)
    usage
    # Ignoring because those are defined in common.sh, and don't need quotes
    # shellcheck disable=SC2086
    exit $EXIT_OK
    ;;
  esac
done

###################################################
# Init. Variables
###################################################
DEPLOYMENT_TEMP_FOLDER="$(mktemp -d)"
VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH=$DEPLOYMENT_TEMP_FOLDER

###################################################
# Verify
###################################################
if [ "${GENERATE_YAML_ONLY}" = "false" ]; then
  # Create required assets, including container images.

  if [ "${CONTAINER_IMAGE_BUILD_METHOD}" = "KANIKO" ] && [ "${CONTAINER_REPO_TYPE}" = "${CONST_CONTAINER_REPO_TYPE_GCR}" ]; then
    echo "[Error] Kaniko build only supports Repo Type [Private]"
    # Ignoring because those are defined in common.sh, and don't need quotes
    # shellcheck disable=SC2086
    exit $EXIT_GENERIC_ERR
  fi

  if [ "${CONTAINER_REPO_TYPE}" = "${CONST_CONTAINER_REPO_TYPE_PRIVATE}" ]; then
    check_argument "${CONTAINER_REPO_HOST}" "${CONTAINER_REPO_HOST_DESCRIPTION}"
    check_argument "${CONTAINER_REPO_USERNAME}" "${CONTAINER_REPO_USERNAME_DESCRIPTION}"
    check_argument "${CONTAINER_REPO_PASSWORD}" "${CONTAINER_REPO_PASSWORD_DESCRIPTION}"
    check_argument "${CONTAINER_REPO_REPOSITORY_NAME}" "${CONTAINER_REPO_REPOSITORY_NAME_DESCRIPTION}"
  fi

  # If the customer choose to use Artifact Registry to store container images.
  # The Artiffact Registry uses the url format: ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REGISTRY_NAME}/${IMAGE_NAME}:${TAG}
  # Terraform automatically generated a default Artifact Registy with the namimg format: <REGION>-docker.pkg.dev/<PROJECT>/<REGION>-viai-applications
  # Here we assemble correct Artifact Registry name:
  # - If the use specified a Artifact Registry repo name, use the name.
  # - If the user does not specify a Artifact Registry repo name, use default.
  if [ "${CONTAINER_REPO_TYPE}" = "${CONST_CONTAINER_REPO_TYPE_ARTIFACTREGISTRY}" ]; then
    check_argument "${CONTAINER_REPO_HOST}" "${CONTAINER_REPO_HOST_DESCRIPTION}"
    # check_argument "${CONTAINER_REPO_REPOSITORY_NAME}" "${CONTAINER_REPO_REPOSITORY_NAME_DESCRIPTION}"

    ARTIFACTS_REGISTRY_DEFAULT_REG_NAME=$(echo "${CONTAINER_REPO_HOST}" | sed 's/-docker.pkg.dev//g')-viai-applications
    echo "ARTIFACTS_REGISTRY_DEFAULT_REG_NAME=${ARTIFACTS_REGISTRY_DEFAULT_REG_NAME}"
    if ! check_optional_argument "${CONTAINER_REPO_REPOSITORY_NAME}" "${CONTAINER_REPO_REPOSITORY_NAME_DESCRIPTION}" "Use default name:${ARTIFACTS_REGISTRY_DEFAULT_REG_NAME}."; then
      CONTAINER_REPO_REPOSITORY_NAME="${GOOGLE_CLOUD_PROJECT}/${ARTIFACTS_REGISTRY_DEFAULT_REG_NAME}"
    else
      CONTAINER_REPO_REPOSITORY_NAME="${GOOGLE_CLOUD_PROJECT}/${CONTAINER_REPO_REPOSITORY_NAME}"
    fi
    echo "Using Artifact Registry: ${CONTAINER_REPO_HOST}/${CONTAINER_REPO_REPOSITORY_NAME}"
  fi

  if [ "${CONTAINER_REPO_TYPE}" = "${CONST_CONTAINER_REPO_TYPE_GCR}" ]; then
    CONTAINER_REPO_REPOSITORY_NAME="${GOOGLE_CLOUD_PROJECT}"
    if [ -z "${CONTAINER_REPO_HOST}" ]; then
      echo "No container host specified, use gcr.io"
      CONTAINER_REPO_HOST="gcr.io"
    fi
  fi

  if [ -z "${ANTHOS_SERVICE_ACCOUNT_KEY_PATH}" ] && [ -z "${ANTHOS_SERVICE_ACCOUNT_EMAIL}" ]; then
    echo "[ERROR] One of ANTHOS_SERVICE_ACCOUNT_KEY_PATH or ANTHOS_SERVICE_ACCOUNT_EMAIL must be specified."
    # Ignoring because those are defined in common.sh, and don't need quotes
    # shellcheck disable=SC2086
    exit $EXIT_GENERIC_ERR
  fi
else
  # Generate YAML files only.
  check_optional_argument "${CAMERA_ID_RANGE}" "${CAMERA_ID_RANGE_DESCRIPTION}" "Use default application yaml file."
  check_argument "${CAMERA_APPLICATION_CONTAIMER_IMAGE_URL}" "${CAMERA_APPLICATION_CONTAIMER_IMAGE_URL_DESCRIPTION}"
fi

###################################################
# Get Camera Start ID and End ID
###################################################
CAMERA_ID_START=
CAMERA_ID_END=

if [ -n "${CAMERA_ID_RANGE}" ]; then
  IFS='-'
  # We need the original value, so do not double quote the string. Otherwise we are unable to split it into an array
  # shellcheck disable=SC2086
  set -- $CAMERA_ID_RANGE
  CAMERA_ID_START=$1
  CAMERA_ID_END=$2
  unset IFS

  echo "Camera ID: ${CAMERA_ID_START} to ${CAMERA_ID_END}"
fi

###################################################
# Edge Server Set up
###################################################
if [ "${GENERATE_YAML_ONLY}" = "false" ]; then
  # Create required assets, including container images.
  echo "Setting up server..."

  if [ -z "${ANTHOS_SERVICE_ACCOUNT_KEY_PATH}" ]; then
    echo "[Generating Assets] Generating service account key file..."

    cleanup_gcloud_auth

    GOOGLE_APPLICATION_CREDENTIALS_PATH="/root/.config/gcloud/application_default_credentials.json"

    docker run -it --rm \
      -e GOOGLE_APPLICATION_CREDENTIALS="${GOOGLE_APPLICATION_CREDENTIALS_PATH}" \
      -v /etc/localtime:/etc/localtime:ro \
      -v "${DEPLOYMENT_TEMP_FOLDER}":/data \
      --volumes-from "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" \
      "${GCLOUD_CLI_CONTAINER_IMAGE_ID}" \
      gcloud iam service-accounts keys create /data/service-account-key.json --iam-account="${ANTHOS_SERVICE_ACCOUNT_EMAIL}"
  else
    echo "[Generating Assets] cp ${ANTHOS_SERVICE_ACCOUNT_KEY_PATH} ${DEPLOYMENT_TEMP_FOLDER}/service-account-key.json..."
    cp "${ANTHOS_SERVICE_ACCOUNT_KEY_PATH}" "${DEPLOYMENT_TEMP_FOLDER}/service-account-key.json"
  fi
  ANTHOS_SERVICE_ACCOUNT_KEY_PATH="${DEPLOYMENT_TEMP_FOLDER}/service-account-key.json"
fi

###################################################
# Application Set up
###################################################
if [ "${GENERATE_YAML_ONLY}" = "false" ]; then
  # Create required assets, including container images.
  # Build Application and Push to Container Repo
  VIAI_CAMERA_APP_IMAGE_TAG=$(date "+%F-%H%M%S")
  BUILD_SCRIPT_FILE=

  if [ "${CONTAINER_IMAGE_BUILD_METHOD}" = "GCP" ]; then
    echo "[Generating Assets] Build container image with Cloud Build"
    BUILD_SCRIPT_FILE="$(pwd)"/scripts/application-build-cloud-viai-camera-app.sh
  else
    echo "[Generating Assets] Build container image with Kaniko"
    BUILD_SCRIPT_FILE="$(pwd)"/scripts/application-build-kaniko-viai-camera-app.sh
  fi
  echo "** Running build script:${BUILD_SCRIPT_FILE}."

  bash "${BUILD_SCRIPT_FILE}" \
    -H "${CONTAINER_REPO_HOST}" \
    -U "${CONTAINER_REPO_USERNAME}" \
    -W "${CONTAINER_REPO_PASSWORD}" \
    -N "${CONTAINER_REPO_REPOSITORY_NAME}" \
    -p "${GOOGLE_CLOUD_PROJECT}" \
    -l "${VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL}" \
    -b "${VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH}" \
    -T "${VIAI_CAMERA_APP_IMAGE_TAG}" \
    -a "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}" \
    -o "${DEPLOYMENT_TEMP_FOLDER}" \
    -Y "${CONTAINER_REPO_TYPE}"
fi

########################
# Update YAML Templates
########################

if [ "${CONTAINER_REPO_TYPE}" = "${CONST_CONTAINER_REPO_TYPE_GCR}" ]; then
  cp "${WORKING_DIRECTORY}/kubernetes/viai-camera-integration/viai-camera-integration-gcp.yaml.tmpl" "$DEPLOYMENT_TEMP_FOLDER/viai-camera-integration.yaml"
else
  cp "${WORKING_DIRECTORY}/kubernetes/viai-camera-integration/viai-camera-integration-private-repo.yaml.tmpl" "$DEPLOYMENT_TEMP_FOLDER/viai-camera-integration.yaml"
fi
# Copy namespace yaml and update viai app yaml
cp "${WORKING_DIRECTORY}/kubernetes/viai-camera-integration/namespace.yaml" "$DEPLOYMENT_TEMP_FOLDER/namespace.yaml"

if [ -z "${CAMERA_ID_START}" ] && [ -z "${CAMERA_ID_END}" ]; then
  # Update VIAI Client Application Yaml file
  update_camera_app_yaml_template "${GENERATE_YAML_ONLY}" \
    "${DEPLOYMENT_TEMP_FOLDER}/viai-camera-integration.yaml" \
    "${CAMERA_APPLICATION_CONTAIMER_IMAGE_URL}" \
    "${CONTAINER_REPO_HOST}" \
    "${CONTAINER_REPO_REPOSITORY_NAME}" \
    "${VIAI_CAMERA_APP_IMAGE_TAG}" \
    "${GOOGLE_CLOUD_PROJECT}" \
    "0"
  echo "[Generating Assets] Updating VIAI Client Application Secrets"
else
  # Create and Update VIAI Client Application Yaml files
  CAMERA_ID_INDEX=${CAMERA_ID_START}
  while [ "$CAMERA_ID_INDEX" -le "${CAMERA_ID_END}" ]; do
    cp "$DEPLOYMENT_TEMP_FOLDER/viai-camera-integration.yaml" "$DEPLOYMENT_TEMP_FOLDER/viai-camera-integration-${CAMERA_ID_INDEX}.yaml"
    update_camera_app_yaml_template "${GENERATE_YAML_ONLY}" \
      "${DEPLOYMENT_TEMP_FOLDER}/viai-camera-integration-${CAMERA_ID_INDEX}.yaml" \
      "${CAMERA_APPLICATION_CONTAIMER_IMAGE_URL}" \
      "${CONTAINER_REPO_HOST}" \
      "${CONTAINER_REPO_REPOSITORY_NAME}" \
      "${VIAI_CAMERA_APP_IMAGE_TAG}" \
      "${GOOGLE_CLOUD_PROJECT}" \
      "${CAMERA_ID_INDEX}"
    CAMERA_ID_INDEX=$((CAMERA_ID_INDEX + 1))
  done
  echo "Deleting template file: $DEPLOYMENT_TEMP_FOLDER/viai-camera-integration.yaml..."
  rm "$DEPLOYMENT_TEMP_FOLDER/viai-camera-integration.yaml"
fi

if [ "${GENERATE_YAML_ONLY}" = "false" ]; then
  echo "[Generating Assets] Updating VIAI Client Application Secrets"

  # shellcheck disable=SC2240
  "${WORKING_DIRECTORY}"/scripts/application-create-secrets-viai-client.sh \
    -o "${DEPLOYMENT_TEMP_FOLDER}" \
    -k "${VIAI_CLIENT_INTEGRATION_SERVICE_ACCOUNT_KEY_PATH}"

  # Update Image Pull Secrets
  if [ "${CONTAINER_REPO_TYPE}" = "${CONST_CONTAINER_REPO_TYPE_GCR}" ] || [ "${CONTAINER_REPO_TYPE}" = "${CONST_CONTAINER_REPO_TYPE_ARTIFACTREGISTRY}" ]; then
    echo "[Generating Assets] Updating Image Pull Secrets for GCR: ${ANTHOS_SERVICE_ACCOUNT_KEY_PATH}"

    # shellcheck disable=SC2240
    ./scripts/application-create-secrets-gcr.sh \
      -o "${DEPLOYMENT_TEMP_FOLDER}" \
      -k "${ANTHOS_SERVICE_ACCOUNT_KEY_PATH}" \
      -H "${CONTAINER_REPO_HOST}"
  else
    echo "[Generating Assets] Updating Image Pull Secrets for Private Repo"

    # shellcheck disable=SC2240
    ./scripts/application-create-secrets-private-repo.sh \
      -H "${CONTAINER_REPO_HOST}" \
      -U "${CONTAINER_REPO_USERNAME}" \
      -W "${CONTAINER_REPO_PASSWORD}" \
      -o "${DEPLOYMENT_TEMP_FOLDER}" \
      -N "${CONTAINER_REPO_REPOSITORY_NAME}" \
      -k "${ANTHOS_SERVICE_ACCOUNT_KEY_PATH}"
  fi
fi

if [ "${GENERATE_YAML_ONLY}" = "false" ]; then
  # Create required assets, including container images.
  ###### Push Dependencies images such as Mosquitto to Private Repo and Update dependencies yaml files
  # Mosquitto: starting from mosquitto:2.0.0, by default it only allows connections from localhost,
  #           unless explictly edit mosquitto.config `bind_interface device`` or `bind_address ip_address`
  # Use Digest to ensure we are pulling Linux image
  TARGET_IMAGE="eclipse-mosquitto:1.6.15"
  SOURCE_IMAGE="${TARGET_IMAGE}@sha256:abc6b06c4b65adca0d1330e6ef58f795c77c22a0229ba8e465014acfaab451b3"

  if [ "${CONTAINER_REPO_TYPE}" = "${CONST_CONTAINER_REPO_TYPE_PRIVATE}" ]; then
    # If edge server cannot connect to the internet, they must pull images from private repo.
    echo "[Generating Assets] Pushing Dependencies images such as Mosquitto to Private Repo and Updating dependencies yaml files"
    # shellcheck disable=SC2240
    ./scripts/application-prepare-dependency-yaml.sh \
      -H "${CONTAINER_REPO_HOST}" \
      -U "${CONTAINER_REPO_USERNAME}" \
      -W "${CONTAINER_REPO_PASSWORD}" \
      -o "${DEPLOYMENT_TEMP_FOLDER}" \
      -N "${CONTAINER_REPO_REPOSITORY_NAME}" \
      -Y "${CONTAINER_REPO_TYPE}" \
      -x "${SOURCE_IMAGE}" \
      -X "${TARGET_IMAGE}"
  else
    echo "[Generating Assets] Pushing Dependencies images such as Mosquitto to GCR and Updating dependencies yaml files"
    # shellcheck disable=SC2240
    echo "CONTAINER_REPO_REPOSITORY_NAME=${CONTAINER_REPO_REPOSITORY_NAME}"
    ./scripts/application-prepare-dependency-yaml.sh \
      -H "${CONTAINER_REPO_HOST}" \
      -o "${DEPLOYMENT_TEMP_FOLDER}" \
      -N "${CONTAINER_REPO_REPOSITORY_NAME}" \
      -Y "${CONTAINER_REPO_TYPE}" \
      -x "${SOURCE_IMAGE}" \
      -X "${TARGET_IMAGE}"
  fi

  echo "Push ${SOURCE_IMAGE} to ${CONTAINER_REPO_HOST}/${CONTAINER_REPO_REPOSITORY_NAME}/${TARGET_IMAGE}"

  cp "${WORKING_DIRECTORY}/kubernetes/mosquitto/mosquitto.yaml.tmpl" "$DEPLOYMENT_TEMP_FOLDER/mosquitto.yaml"

  # This is an environment variable and a template variable, use single quota to avoid replacment
  # shellcheck disable=SC2016
  replace_variables_in_template 's/${CONTAINER_REPO_HOST}/'"${CONTAINER_REPO_HOST}"'/g' "$DEPLOYMENT_TEMP_FOLDER/mosquitto.yaml"
  escape_slash "${CONTAINER_REPO_REPOSITORY_NAME}"
  # This is an environment variable and a template variable, use single quota to avoid replacment
  # shellcheck disable=SC2016
  replace_variables_in_template 's/${CONTAINER_REPO_REPOSITORY_NAME}/'"${ESCAPED_NAME}"'/g' "$DEPLOYMENT_TEMP_FOLDER/mosquitto.yaml"
  unset ESCAPED_NAME

  # This is an environment variable and a template variable, use single quota to avoid replacment
  # shellcheck disable=SC2016
  replace_variables_in_template 's/${VIAI_CAMERA_APP_IMAGE_TAG}/'"${TARGET_IMAGE}"'/g' "$DEPLOYMENT_TEMP_FOLDER/mosquitto.yaml"

fi

# Copy files
mkdir -p "${DEPLOYMENT_TEMP_FOLDER}"/scripts
cp "${WORKING_DIRECTORY}/scripts/machine-install-prerequisites.sh" "${DEPLOYMENT_TEMP_FOLDER}/scripts/"
cp "${WORKING_DIRECTORY}/scripts/common.sh" "${DEPLOYMENT_TEMP_FOLDER}/scripts/"
cp "${WORKING_DIRECTORY}/scripts/gcp-anthos-attach-cluster.sh" "${DEPLOYMENT_TEMP_FOLDER}/scripts/"

mkdir -p "${DEPLOYMENT_TEMP_FOLDER}/kubernetes"
mv "${DEPLOYMENT_TEMP_FOLDER}"/*.yaml "${DEPLOYMENT_TEMP_FOLDER}/kubernetes/"

if ! check_optional_argument "${ANTHOS_MEMBERSHIP_NAME}" "${ANTHOS_MEMBERSHIP_NAME_DESCRIPTION}" "Use hostname [$(hostname)] as Anthos Bare Metal membership name."; then
  ANTHOS_MEMBERSHIP_NAME=$(hostname)
fi

########################################################################
# Deploy Application
########################################################################
cp "${WORKING_DIRECTORY}/edge-server/${K8S_RUNTIME}/deploy-app.sh" "${DEPLOYMENT_TEMP_FOLDER}/scripts/"

cat <<EOF >"${DEPLOYMENT_TEMP_FOLDER}/scripts/1-deploy-app.sh"
#!/usr/bin/env sh
cd /var/lib/viai/

mkdir -p ./log

. /var/lib/viai/scripts/deploy-app.sh \\
  --k8s-runtime "${K8S_RUNTIME}" \\
  --membership "${ANTHOS_MEMBERSHIP_NAME}" \\
  2>&1 | tee ./log/deploy-app.log
EOF

cleanup_gcloud_auth

rm -rf "${DEPLOYMENT_TEMP_FOLDER}/config.json"
rm -rf "${DEPLOYMENT_TEMP_FOLDER}/private-repo-config.json"

OUTPUT_FOLDER="${DEPLOYMENT_TEMP_FOLDER}"
export OUTPUT_FOLDER

echo "[Generating Assets] Completed."
echo "VIAI application assets have been generated at: ${OUTPUT_FOLDER}"
