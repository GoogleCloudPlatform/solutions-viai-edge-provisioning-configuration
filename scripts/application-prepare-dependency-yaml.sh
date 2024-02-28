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
# shellcheck disable=SC1091
. scripts/common.sh
# Doesn't follow symlinks, but it's likely expected for most users
SCRIPT_BASENAME="$(basename "${0}")"

CONTAINER_REPO_HOST_DESCRIPTION="private container repo host name, ex, repo.private.com"
CONTAINER_REPO_USERNAME_DESCRIPTION="private container repo user name"
CONTAINER_REPO_PASSWORD_DESCRIPTION="passowrd of the private container repo user"
CONTAINER_REPO_REPOSITORY_NAME_DESCRIPION="name of private repo registry"
DEPLOYMENT_TEMP_FOLDER_DESCRIPTION="output folder path"
REPO_TYPE_DESCRIPTION="Container Registry type, can be [GCR] or [Private]"
SOURCE_IMAGE_DESCRIPTION="Source image URL, ex. gcr.io/my-project/my-image:latest"
TARGET_IMAGE_NAME_DESCRIPTION="Target image name, ex, my-container-image:latest"

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script prepares denendencies for the VIAI application deployment."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -H $(is_linux && echo "| --container-repo-host"): ${CONTAINER_REPO_HOST_DESCRIPTION}"
  echo "  -U $(is_linux && echo "| --container-repo-user"): ${CONTAINER_REPO_USERNAME_DESCRIPTION}"
  echo "  -W $(is_linux && echo "| --container-repo-password"): ${CONTAINER_REPO_PASSWORD_DESCRIPTION}"
  echo "  -N $(is_linux && echo "| --container-repo-reg-name"): ${CONTAINER_REPO_REPOSITORY_NAME_DESCRIPION}"
  echo "  -o $(is_linux && echo "| --output-path"): ${DEPLOYMENT_TEMP_FOLDER_DESCRIPTION}"
  echo "  -Y $(is_linux && echo "| --repo-type"): ${REPO_TYPE_DESCRIPTION}"
  echo "  -x $(is_linux && echo "--source-image"): ${SOURCE_IMAGE_DESCRIPTION}"
  echo "  -X $(is_linux && echo "--target-image"): ${TARGET_IMAGE_NAME_DESCRIPTION}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,container-repo-host:,container-repo-user:,container-repo-password:,container-repo-reg-name:,output-path:,repo-type:,source-image:,target-image:"
SHORT_OPTIONS="hH:N:U:W:X:Y:o:x:"

CONTAINER_REPO_HOST=
CONTAINER_REPO_USERNAME=
CONTAINER_REPO_PASSWORD=
CONTAINER_REPO_REPOSITORY_NAME=
CONTAINER_REPO_TYPE=
DEPLOYMENT_TEMP_FOLDER=
SOURCE_IMAGE=
TARGET_IMAGE_NAME=

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
  -N | --container-repo-reg-name)
    CONTAINER_REPO_REPOSITORY_NAME="${2}"
    shift 2
    ;;
  -o | --output-path)
    DEPLOYMENT_TEMP_FOLDER="${2}"
    shift 2
    ;;
  -Y | --repo-type)
    CONTAINER_REPO_TYPE="${2}"
    shift 2
    ;;
  -x | --source-image)
    SOURCE_IMAGE="${2}"
    shift 2
    ;;
  -X | --target-image)
    TARGET_IMAGE_NAME="${2}"
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

if [ -z "${SOURCE_IMAGE}" ] || [ -z "${TARGET_IMAGE_NAME}" ] || [ -z "${DEPLOYMENT_TEMP_FOLDER}" ]; then
  echo "One of SOURCE_IMAGE, TARGET_IMAGE_NAME or DEPLOYMENT_TEMP_FOLDER not set."
  usage
  # Ignoring because those are defined in common.sh, and don't need quotes
  # shellcheck disable=SC2086
  exit ${EXIT_GENERIC_ERR}
fi

if [ "$CONTAINER_REPO_TYPE" = "${CONST_CONTAINER_REPO_TYPE_PRIVATE}" ]; then
  echo "Pushing Mosquitto image to private repo..."
  docker build -t private_repo_pull_tool:1.0.0 "${WORKING_DIRECTORY}"/docker/copy-images
  # DOCKER_HOST to fix "Cannot connect to the Docker daemon at tcp://docker:2375. Is the docker daemon running?" issue
  docker run -it --rm \
    --privileged \
    -e SOURCE_IMAGE="${SOURCE_IMAGE}" \
    -e TARGET_IMAGE_NAME="${TARGET_IMAGE_NAME}" \
    -e REGISTRY_TYPE="${CONTAINER_REPO_TYPE}" \
    -e CONTAINER_REPO_HOST="${CONTAINER_REPO_HOST}" \
    -e CONTAINER_REPO_USERNAME="${CONTAINER_REPO_USERNAME}" \
    -e CONTAINER_REPO_PASSWORD="${CONTAINER_REPO_PASSWORD}" \
    -e CONTAINER_REPO_REPOSITORY_NAME="${CONTAINER_REPO_REPOSITORY_NAME}" \
    -v "$DEPLOYMENT_TEMP_FOLDER":/data \
    -e DOCKER_HOST="tcp://127.0.0.1:2375" \
    "private_repo_pull_tool:1.0.0"
else
  echo "Pushing Mosquitto image to GCR:${CONTAINER_REPO_REPOSITORY_NAME}"
  GOOGLE_APPLICATION_CREDENTIALS_PATH="/root/.config/gcloud/application_default_credentials.json"
  docker build -t gcr_pull_tool:1.0.0 "${WORKING_DIRECTORY}"/docker/copy-images

  docker run -it --rm \
    --privileged \
    -e SOURCE_IMAGE="${SOURCE_IMAGE}" \
    -e TARGET_IMAGE_NAME="${TARGET_IMAGE_NAME}" \
    -e REGISTRY_TYPE="${CONTAINER_REPO_TYPE}" \
    -e CONTAINER_REPO_HOST="${CONTAINER_REPO_HOST}" \
    -e CONTAINER_REPO_REPOSITORY_NAME="${CONTAINER_REPO_REPOSITORY_NAME}" \
    -e GOOGLE_APPLICATION_CREDENTIALS="${GOOGLE_APPLICATION_CREDENTIALS_PATH}" \
    -v /etc/localtime:/etc/localtime:ro \
    --volumes-from "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" \
    -v "$DEPLOYMENT_TEMP_FOLDER":/data \
    -e DOCKER_HOST="tcp://127.0.0.1:2375" \
    "gcr_pull_tool:1.0.0"
fi
