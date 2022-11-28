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
CONTAINER_REPO_HOST_DESCRIPTION="private container repo host name, ex, repo.private.com"
CONTAINER_REPO_USERNAME_DESCRIPTION="private container repo user name"
CONTAINER_REPO_PASSWORD_DESCRIPTION="passowrd of the private container repo user"
CONTAINER_REPO_REPOSITORY_NAME_DESCRIPION="name of private repo registry"
DEPLOYMENT_TEMP_FOLDER_DESCRIPTION="output folder path"
SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION="path of image pull secret service account key file."

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script creates kubernetes secrets for pulling images from GCR."
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
  echo "  -k $(is_linux && echo "| --service-account-key-path"): ${SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,container-repo-reg-name:,container-repo-host:,container-repo-user:,container-repo-password:,output-path:,service-account-key-path:"
SHORT_OPTIONS="hH:N:U:W:k:o:"

CONTAINER_REPO_HOST=
CONTAINER_REPO_USERNAME=
CONTAINER_REPO_PASSWORD=
CONTAINER_REPO_REPOSITORY_NAME=
DEPLOYMENT_TEMP_FOLDER=
SERVICE_ACCOUNT_KEY_PATH=

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
    # For different container registry type, ex, GCR may no require this, but private registry may require this.
    # shellcheck disable=SC2034
    CONTAINER_REPO_HOST="${2}"
    shift 2
    ;;
  -U | --container-repo-user)
    # For different container registry type, ex, GCR may no require this, but private registry may require this.
    # shellcheck disable=SC2034
    CONTAINER_REPO_USERNAME="${2}"
    shift 2
    ;;
  -W | --container-repo-password)
    # For different container registry type, ex, GCR may no require this, but private registry may require this.
    # shellcheck disable=SC2034
    CONTAINER_REPO_PASSWORD="${2}"
    shift 2
    ;;
  -N | --container-repo-reg-name)
    # For different container registry type, ex, GCR may no require this, but private registry may require this.
    # shellcheck disable=SC2034
    CONTAINER_REPO_REPOSITORY_NAME="${2}"
    shift 2
    ;;
  -o | --output-path)
    DEPLOYMENT_TEMP_FOLDER="${2}"
    shift 2
    ;;
  -k | --service-account-key-path)
    # For different container registry type, ex, GCR may no require this, but private registry may require this.
    # shellcheck disable=SC2034
    SERVICE_ACCOUNT_KEY_PATH="${2}"
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
    break
    ;;
  esac
done

echo "Checking if service account key file exists at ${SERVICE_ACCOUNT_KEY_PATH}"

if [ -f "${SERVICE_ACCOUNT_KEY_PATH}" ]; then
  echo "Generating configuration file for GCR..."
  cp "${WORKING_DIRECTORY}/kubernetes/viai-camera-integration/secret_image_pull.yaml.tmpl" "${DEPLOYMENT_TEMP_FOLDER}/secret_image_pull.yaml"
  docker build -t viai-camera-app-utility:1.0.0 "$(pwd)/docker/private-repo"

  docker run -it --rm \
    -e CONTAINER_REPO_HOST="${CONTAINER_REPO_HOST}" \
    -e CONTAINER_REPO_USERNAME="_json_key" \
    -e CONTAINER_REPO_PASSWORD="$(cat "${SERVICE_ACCOUNT_KEY_PATH}")" \
    -v "$DEPLOYMENT_TEMP_FOLDER":/data \
    "viai-camera-app-utility:1.0.0"

  SECRET_PATH="$DEPLOYMENT_TEMP_FOLDER"/private-repo-config.json

  # Permission denied when access private-repo-config.json
  cat "${SECRET_PATH}" >"$DEPLOYMENT_TEMP_FOLDER"/private-repo-config.txt

  IMAGE_PULL_SECRET=$(cat "$DEPLOYMENT_TEMP_FOLDER"/private-repo-config.txt)

  # This is an environment variable and a template variable, use single quota to avoid replacment
  # shellcheck disable=SC2016
  sed -i 's/${IMAGE_PULL_SECRET}/'"${IMAGE_PULL_SECRET}"'/g' "$DEPLOYMENT_TEMP_FOLDER"/secret_image_pull.yaml

  rm "$DEPLOYMENT_TEMP_FOLDER"/private-repo-config.txt
else
  echo "${SERVICE_ACCOUNT_KEY_PATH} does not exists"
  # Ignoring because those are defined in common.sh, and don't need quotes
  # shellcheck disable=SC2086
  exit $ERR_MISSING_DEPENDENCY
fi
