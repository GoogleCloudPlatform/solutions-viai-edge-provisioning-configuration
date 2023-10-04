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

# Ignoring SC2034 because this variable is used in other scripts
# shellcheck disable=SC2034
ANTHOS_VERSION="1.16.0"
# Ignoring SC2034 because this variable is used in other scripts
# shellcheck disable=SC2034
CONST_CONTAINER_REPO_TYPE_GCR="GCR"
# shellcheck disable=SC2034
CONST_CONTAINER_REPO_TYPE_PRIVATE="Private"
# shellcheck disable=SC2034
CONST_CONTAINER_REPO_TYPE_ARTIFACTREGISTRY="ArtifactRegistry"
# shellcheck disable=SC2034
EXIT_OK=0
# shellcheck disable=SC2034
EXIT_GENERIC_ERR=1
# shellcheck disable=SC2034
ERR_VARIABLE_NOT_DEFINED=2
# shellcheck disable=SC2034
ERR_MISSING_DEPENDENCY=3
# shellcheck disable=SC2034
ERR_ARGUMENT_EVAL_ERROR=4
# shellcheck disable=SC2034
ERR_GOOGLE_APPLICATION_CREDENTIALS_NOT_FOUND=5
# shellcheck disable=SC2034
ERR_DIRECTORY_NOT_FOUND=6
# shellcheck disable=SC2034
ERR_UNSUPPORTED_OS=7
# shellcheck disable=SC2034
ERR_UNSUPPORTED_OS_DESCRIPTION="[Error]Unsupported OS"
# shellcheck disable=SC2034
HELP_DESCRIPTION="show this help message and exit"
# shellcheck disable=SC2034
GCLOUD_CLI_CONTAINER_IMAGE_ID="gcr.io/google.com/cloudsdktool/cloud-sdk:397.0.0"
if [ -f "docker/terraform/Dockerfile" ]; then
  # shellcheck disable=SC2034
  TERRAFORM_CONTAINER_IMAGE_ID="$(grep <docker/terraform/Dockerfile "hashicorp/terraform" | awk -F ' ' '{print $2}')"
else
  echo "[Warning] docker/terraform/Dockerfile does not exist. Variable TERRAFORM_CONTAINER_IMAGE_ID not set."
fi
# shellcheck disable=SC2034
OS_INSTALLER_IMAGE_URL="https://releases.ubuntu.com/focal/ubuntu-20.04.6-live-server-amd64.iso"
# shellcheck disable=SC2034
OS_IMAGE_CHECKSUM_FILE_URL="https://releases.ubuntu.com/focal/SHA256SUMS"
# shellcheck disable=SC2034
WORKING_DIRECTORY="$(pwd)"
echo "Working directory: ${WORKING_DIRECTORY}"
# shellcheck disable=SC2034
OS_INSTALLER_IMAGE_PATH="${WORKING_DIRECTORY}/$(basename "${OS_INSTALLER_IMAGE_URL}")"

# Gcloud auth container name, reused container volume when gcloud is required in later steps
# shellcheck disable=SC2034
GCLOUD_AUTHENTICATION_CONTAINER_NAME="gcloud-config"

# Allocate a TTY and enable interactive mode only as needed
DOCKER_FLAGS=
if [ -t 0 ]; then
  DOCKER_FLAGS="-it"
fi

check_argument() {
  ARGUMENT_VALUE="${1}"
  ARGUMENT_DESCRIPTION="${2}"

  if [ -z "${ARGUMENT_VALUE}" ]; then
    echo "[ERROR]: ${ARGUMENT_DESCRIPTION} is not defined. Run this command with the -h option to get help. Terminating..."
    # Ignoring because those are defined in common.sh, and don't need quotes
    # shellcheck disable=SC2086
    exit ${ERR_VARIABLE_NOT_DEFINED}
  else
    echo "[OK]: ${ARGUMENT_DESCRIPTION} value is defined: ${ARGUMENT_VALUE}"
  fi

  unset ARGUMENT_NAME
  unset ARGUMENT_VALUE
}

check_optional_argument() {
  ARGUMENT_VALUE="${1}"
  shift
  ARGUMENT_DESCRIPTION="${1}"
  shift
  VALUE_NOT_DEFINED_MESSAGE="$*"

  if [ -z "${ARGUMENT_VALUE}" ]; then
    echo "[OK]: optional ${ARGUMENT_DESCRIPTION} is not defined."
    RET_CODE=1
    if [ -n "${VALUE_NOT_DEFINED_MESSAGE}" ]; then
      echo "${VALUE_NOT_DEFINED_MESSAGE}"
    fi
  else
    echo "[OK]: optional ${ARGUMENT_DESCRIPTION} value is defined: ${ARGUMENT_VALUE}"
    RET_CODE=0
  fi

  unset ARGUMENT_NAME
  unset ARGUMENT_VALUE
  unset VALUE_NOT_DEFINED_MESSAGE
  return ${RET_CODE}
}

check_exec_dependency() {
  EXECUTABLE_NAME="${1}"

  if ! command -v "${EXECUTABLE_NAME}" >/dev/null 2>&1; then
    # shellcheck disable=SC2116,SC2086,SC2086,SC2086
    echo "[ERROR]: ${EXECUTABLE_NAME} command is not available, but it's needed. Make it available in PATH and try again. Terminating..."
    exit ${ERR_MISSING_DEPENDENCY}
  else
    echo "[OK]: ${EXECUTABLE_NAME} is available in PATH, pointing to: $(command -v "${EXECUTABLE_NAME}")"
  fi

  unset EXECUTABLE_NAME
}

clone_git_repository_if_not_cloned_already() {
  GIT_REPOSITORY_URL="${1}"
  DESTINATION_DIR="${2}"

  if [ -z "${DESTINATION_DIR}" ]; then
    echo "ERROR while cloning the ${GIT_REPOSITORY_URL} git repository: The DESTINATION_DIR variable is not set, or set to an empty string"
    exit 1
  fi

  GIT_DIRECTORY_PATH="${DESTINATION_DIR}/.git"
  if [ -d "${GIT_DIRECTORY_PATH}" ]; then
    echo "${GIT_DIRECTORY_PATH} already exists. Assuming that you already cloned ${GIT_REPOSITORY_URL}. Skipping clone..."
  else
    mkdir -p "${DESTINATION_DIR}"
    echo "Cloning ${GIT_REPOSITORY_URL} in ${DESTINATION_DIR}..."
    git clone "${GIT_REPOSITORY_URL}" "${DESTINATION_DIR}"
  fi

  unset GIT_DIRECTORY_PATH
  unset DESTINATION_DIR
  unset GIT_REPOSITORY_URL
}

download_file_if_necessary() {
  FILE_TO_DOWNLOAD_URL="${1}"
  FILE_TO_DOWNLOAD_PATH="${2}"

  if [ ! -f "${FILE_TO_DOWNLOAD_PATH}" ]; then
    curl \
      --fail \
      --location \
      --output "${FILE_TO_DOWNLOAD_PATH}" \
      "${FILE_TO_DOWNLOAD_URL}"
  else
    echo "${FILE_TO_DOWNLOAD_PATH} already exists. Skipping download of ${FILE_TO_DOWNLOAD_URL}"
  fi

  unset FILE_TO_DOWNLOAD_URL
  unset FILE_TO_DOWNLOAD_PATH
}

is_linux() {
  os_name="$(uname -s)"
  if test "${os_name#*"Linux"}" != "$os_name"; then
    unset os_name
    return ${EXIT_OK}
  else
    unset os_name
    return ${EXIT_GENERIC_ERR}
  fi
}

is_macos() {
  os_name="$(uname -s)"
  if test "${os_name#*"Darwin"}" != "$os_name"; then
    unset os_name
    return 0
  else
    unset os_name
    return ${EXIT_GENERIC_ERR}
  fi
}

run_containerized_terraform() {
  GOOGLE_APPLICATION_CREDENTIALS_PATH="${1}"
  shift
  VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH="${1}"
  shift

  echo "Running: terraform $*"
  echo "Using VIAI Camera application source codes path: ${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}"

  # shellcheck disable=SC2068
  docker run \
    ${DOCKER_FLAGS} \
    --rm \
    -e GOOGLE_APPLICATION_CREDENTIALS="${GOOGLE_APPLICATION_CREDENTIALS_PATH}" \
    -v "$(pwd)":/workspace \
    -v /etc/localtime:/etc/localtime:ro \
    -v "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}":/packages \
    -w "/workspace/terraform" \
    --volumes-from gcloud-config \
    "${TERRAFORM_CONTAINER_IMAGE_ID}" "$@"
}

clone_viai_camera_app() {
  VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH=${1}
  GIT_URL=${2}
  GIT_BRANCH=${3}
  echo "Cloning VIAI Camera from ${GIT_URL}:${GIT_BRANCH}"

  clone_git_repository_if_not_cloned_already "${GIT_URL}" "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}/viai-edge-camera-integration"
  git -C "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}/viai-edge-camera-integration" pull origin "${GIT_BRANCH}"
}

gcloud_auth() {
  cleanup_gcloud_auth

  docker run \
    ${DOCKER_FLAGS} \
    --name "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" \
    "${GCLOUD_CLI_CONTAINER_IMAGE_ID}" \
    gcloud auth login --update-adc
}

ensure_tf_backend() {
  GCP_CREDENTIALS_PATH="${1}"
  shift
  TF_STATA_BUCKET_NAME="gs://tf-state-${DEFAULT_PROJECT}/"
  if ! is_tf_state_bucket_exists "${GCP_CREDENTIALS_PATH}"; then
    echo "Creating..."
    gcloud_exec_cmds "${GOOGLE_APPLICATION_CREDENTIALS_PATH}" "gsutil mb -p ${DEFAULT_PROJECT} --pap enforced -b on -l ${DEFAULT_REGION} ${TF_STATA_BUCKET_NAME}"
  fi

  if ! is_tf_state_bucket_exists "${GCP_CREDENTIALS_PATH}"; then
    echo "Unable to create backend storage bucket, exit..."
    exit $EXIT_GENERIC_ERR
  fi

  unset DOCKER_RUN_OUTPUT
}

destroy_tf_backend() {
  GCP_CREDENTIALS_PATH="${1}"
  shift
  TF_STATA_BUCKET_NAME="gs://tf-state-${DEFAULT_PROJECT}/"
  if is_tf_state_bucket_exists "${GCP_CREDENTIALS_PATH}"; then
    gcloud_exec_cmds "${GOOGLE_APPLICATION_CREDENTIALS_PATH}" "gsutil rm -r ${TF_STATA_BUCKET_NAME}"
  fi

  unset DOCKER_RUN_OUTPUT
  unset TF_STATA_BUCKET_NAME
}

is_tf_state_bucket_exists() {
  GCP_CREDENTIALS_PATH="${1}"
  shift
  TF_STATE_BUCKET="gs://tf-state-${DEFAULT_PROJECT}/"

  # shellcheck disable=SC2155,SC2046
  DOCKER_RUN_OUTPUT=$(docker run --rm \
    ${DOCKER_FLAGS} \
    -e GCP_CREDENTIALS_PATH="${GCP_CREDENTIALS_PATH}" \
    --volumes-from gcloud-config \
    --name gcloud_exec_command \
    "${GCLOUD_CLI_CONTAINER_IMAGE_ID}" sh -c "gsutil list -p ${DEFAULT_PROJECT} | grep ${TF_STATE_BUCKET}")

  if echo "${DOCKER_RUN_OUTPUT}" | grep "${TF_STATE_BUCKET}"; then
    echo "Terraform backend storage exists..."
    RET_CODE=0
  else
    echo "Terraform backend does not exist..."
    RET_CODE=1
  fi
  unset TF_STATE_BUCKET
  unset DOCKER_RUN_OUTPUT

  return $RET_CODE
}
gcloud_exec_cmds() {
  GCP_CREDENTIALS_PATH="${1}"
  shift
  # shellcheck disable=SC2068
  docker run --rm \
    ${DOCKER_FLAGS} \
    -e GCP_CREDENTIALS_PATH="${GCP_CREDENTIALS_PATH}" \
    --volumes-from gcloud-config \
    "${GCLOUD_CLI_CONTAINER_IMAGE_ID}" $@
}

cleanup_gcloud_auth() {
  if docker ps -a -f status=exited -f name="${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" | grep -q "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" ||
    docker ps -a -f status=created -f name="${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" | grep -q "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}"; then
    echo "Cleaning the authentication information..."
    docker rm --force --volumes "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}"
  fi
}

apply_kubernetes_menifest() {
  KUBE_MENIFEST_FILE="${1}"
  shift
  KUBECONFIG_PATH="${1}"
  shift

  if [ -f "${KUBE_MENIFEST_FILE}" ]; then
    kubectl apply -f "${KUBE_MENIFEST_FILE}" --kubeconfig="${KUBECONFIG_PATH}"
  else
    echo "${KUBE_MENIFEST_FILE} not found, skip."
  fi
}

escape_slash() {
  ORIGINAL_NAME="${1}"
  shift
  if echo "$ORIGINAL_NAME" | grep -q '/'; then
    # shellcheck disable=SC2034
    ESCAPED_NAME="$(echo "${ORIGINAL_NAME}" | sed 's/\//\\\//g')"
  else
    # shellcheck disable=SC2034
    ESCAPED_NAME="${ORIGINAL_NAME}"
  fi
}

update_camera_app_yaml_template() {
  UPDATE_YAML_ONLY="${1}"

  if [ "${UPDATE_YAML_ONLY}" = "true" ]; then
    YAML_FILE_PATH="${2}"
    CAMERA_APPLICATION_CONTAIMER_IMAGE_URL="${3}"
    INDEX="${8}"
    escape_slash "${CAMERA_APPLICATION_CONTAIMER_IMAGE_URL}"
    # shellcheck disable=SC2016
    replace_variables_in_template 's/${CONTAINER_REPO_HOST}\/${GOOGLE_CLOUD_PROJECT}\/viai-camera-integration:${VIAI_CAMERA_APP_IMAGE_TAG}/'"${ESCAPED_NAME}"'/g' "$YAML_FILE_PATH"
    # shellcheck disable=SC2016
    replace_variables_in_template 's/${CONTAINER_REPO_HOST}\/${CONTAINER_REPO_REPOSITORY_NAME}\/viai-camera-integration:${VIAI_CAMERA_APP_IMAGE_TAG}/'"${ESCAPED_NAME}"'/g' "$YAML_FILE_PATH"
    # shellcheck disable=SC2016
    replace_variables_in_template 's/${INDEX}/'"${INDEX}"'/g' "$YAML_FILE_PATH"
    unset ESCAPED_NAME
  else
    YAML_FILE_PATH="${2}"
    CAMERA_APPLICATION_CONTAIMER_IMAGE_URL="${3}"
    CONTAINER_REPO_HOST="${4}"
    CONTAINER_REPO_REPOSITORY_NAME="${5}"
    VIAI_CAMERA_APP_IMAGE_TAG="${6}"
    GOOGLE_CLOUD_PROJECT="${7}"
    INDEX="${8}"

    # shellcheck disable=SC2016
    replace_variables_in_template 's/${INDEX}/'"${INDEX}"'/g' "$YAML_FILE_PATH"
    # shellcheck disable=SC2016
    replace_variables_in_template 's/${CONTAINER_REPO_HOST}/'"${CONTAINER_REPO_HOST}"'/g' "$YAML_FILE_PATH"

    escape_slash "${CONTAINER_REPO_REPOSITORY_NAME}"
    # This is an environment variable and a template variable, use single quota to avoid replacment
    # shellcheck disable=SC2016
    replace_variables_in_template 's/${CONTAINER_REPO_REPOSITORY_NAME}/'"${ESCAPED_NAME}"'/g' "$YAML_FILE_PATH"
    unset ESCAPED_NAME

    # This is an environment variable and a template variable, use single quota to avoid replacment
    # shellcheck disable=SC2016
    replace_variables_in_template 's/${VIAI_CAMERA_APP_IMAGE_TAG}/'"${VIAI_CAMERA_APP_IMAGE_TAG}"'/g' "$YAML_FILE_PATH"
    # This is an environment variable and a template variable, use single quota to avoid replacment
    # shellcheck disable=SC2016
    replace_variables_in_template 's/${GOOGLE_CLOUD_PROJECT}/'"${GOOGLE_CLOUD_PROJECT}"'/g' "$YAML_FILE_PATH"
  fi
}

replace_variables_in_template() {
  SED_SCRIPT="${1}"
  shift
  FILE_PATH="${1}"
  shift
  if is_linux; then
    # shellcheck disable=SC2016
    sed -i "${SED_SCRIPT}" "${FILE_PATH}"
  elif is_macos; then
    # shellcheck disable=SC2016
    sed -i '' "${SED_SCRIPT}" "${FILE_PATH}"
  else
    echo "${ERR_UNSUPPORTED_OS_DESCRIPTION}"
    exit $ERR_UNSUPPORTED_OS
  fi
}

base64_encode() {
  SECRET_JSON_PATH="${1}"
  shift
  SECRET_JSON_TMP_PATH="${1}"
  shift
  if is_linux; then
    base64 "$SECRET_JSON_PATH" >"$SECRET_JSON_TMP_PATH"
  elif is_macos; then
    base64 -i "$SECRET_JSON_PATH" -o "$SECRET_JSON_TMP_PATH"
  else
    echo "${ERR_UNSUPPORTED_OS_DESCRIPTION}"
    exit $ERR_UNSUPPORTED_OS
  fi
}

# Install NVIDIA cotnainer toolkit and device plugin
# Reference: https://github.com/NVIDIA/k8s-device-plugin
setup_nvidia_container_runtime() {
  # Starting from Anthos Bare Metal 1.13, Containerd is the only supported container runtime
  echo "[Info] invoking setup_nvidia_container_runtime()"
  if [ -z "${1}" ]; then
    echo "[Error] No KUBECONFIG_PATH specified, existing."
    exit $ERR_VARIABLE_NOT_DEFINED
  else
    KUBECONFIG_PATH="${1}"
    echo "[Info] KUBECONFIG_PATH=${KUBECONFIG_PATH}"
    shift
  fi

  CONTAINERD_TOML_PATH="/etc/containerd/config.toml"
  if [ -f "${CONTAINERD_TOML_PATH}" ]; then
    ## Backup original config.toml
    CONTAINERD_TOML_BACKUP_PATH="${CONTAINERD_TOML_PATH}.backup.$(date +%Y%m%d-%H%M%S)"
    echo "Backing up ${CONTAINERD_TOML_PATH} to ${CONTAINERD_TOML_BACKUP_PATH}"
    cp "${CONTAINERD_TOML_PATH}" "${CONTAINERD_TOML_BACKUP_PATH}"

    ## Install NVIDIA-Container-Toolkit
    echo "[Info] Installing NVIDIA Device Plugin"

    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg &&
      curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list &&
      apt-get update

    echo "[Info] Installing nvidia-container-toolkit"
    apt-get update -y
    apt-get install -y nvidia-container-toolkit

    ## update toml file
    ## Add Nvidia runtime configuration section if it does not exists.
    if ! cat ${CONTAINERD_TOML_PATH} | grep -q 'plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia'; then
      echo "config.toml does not contains Nvidia containerd runtime configuration, updating..."
      cat "/var/lib/viai/edge-server/config-section.toml" >>"${CONTAINERD_TOML_PATH}"
    else
      echo "config.toml has already been configured with Nvidia runtime as the default one, skip..."
    fi

    ## Update to use Nvidia runtime.
    ## Update default runtime to nvidia only if the Nvidia runtime configuration section exists.
    if ! grep -q 'default_runtime_name = "nvidia"' "${CONTAINERD_TOML_PATH}" &&
      grep -q 'plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia' "${CONTAINERD_TOML_PATH}"; then
      echo "config.toml does not use Nvidia runtime, updating..."
      sed -i 's/default_runtime_name = "runc"/default_runtime_name = "nvidia"/g' "${CONTAINERD_TOML_PATH}"
    else
      echo "config.toml already been updated with Nvidia default runtime, skip..."
    fi

    ## Restart containerd
    echo "Restarting Containerd service..."
    systemctl restart containerd
    echo "Restarting Containerd service...Done"

    # Install Nvidia Device Pligin
    ## Wait untill containerd is running.
    COUNTER=0

    while [ $COUNTER -lt 30 ]; do
      COUNTER=$((COUNTER + 1))
      sleep 1s
      if systemctl status containerd | grep -q "Active: active (running)"; then
        echo "Containerd is in running state."
        break
      elif [ $COUNTER -lt 30 ]; then
        echo "Containerd is not in running state, waiting..."
      else
        echo "Containerd is not in running state after ${COUNTER} seconds, exit..."
        exit 1
      fi
    done
    if kubectl get ds -n kube-system --kubeconfig="${KUBECONFIG_PATH}" | grep -q "nvidia-device-plugin-daemonset"; then
      echo "nvidia-device-plugin-daemonset exists, deleting"
      kubectl delete ds nvidia-device-plugin-daemonset \
        --kubeconfig="${KUBECONFIG_PATH}" \
        -n kube-system
    fi
    echo "[Info] Creating nvidia-device-plugin-daemonset"
    kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.1/nvidia-device-plugin.yml \
      --kubeconfig="${KUBECONFIG_PATH}"
  else
    echo "[Error]File:${CONTAINERD_TOML_PATH} not found, can not update ${CONTAINERD_TOML_PATH}"
  fi
}
