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

CAMERA_APPLICATION_CONTAIMER_IMAGE_URL_DESCRIPTION="Camera application container registry location. ex, gcr.io/my-project/my-image:latest"
CAMERA_APPLICATION_YAML_PATH_DESCRIPTION="Path of the camera application yaml file."
OUTPUT_FOLDER_DESCRIPTION="output folder path"

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script initializes the environment for Terraform, and runs it. The script will always run terraform init and terraform validate before any subcommand you specify."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -l $(is_linux && echo "| --camera-container-image-location"): ${CAMERA_APPLICATION_CONTAIMER_IMAGE_URL_DESCRIPTION}"
  echo "  -y $(is_linux && echo "| --yaml-file-path"): ${CAMERA_APPLICATION_YAML_PATH_DESCRIPTION}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,camera-container-image-location:,yaml-file-path:"
SHORT_OPTIONS="hl:r:y:"

CAMERA_APPLICATION_CONTAIMER_IMAGE_URL=
CAMERA_APPLICATION_YAML_PATH=

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
  -y | --yaml-file-path)
    CAMERA_APPLICATION_YAML_PATH="${2}"
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

################################
# How to use this script
# 1. Complete 0-generate-edge-server-assets.sh
# 2. If requires multiple camera, run this script to generate multiple yaml files
# * Should modify scripts so it kubectl apply everything
################################

# This is an environment variable and a template variable, use single quota to avoid replacment
if [ -f "${CAMERA_APPLICATION_YAML_PATH}" ]; then
  # shellcheck disable=SC2016
  sed -i 's/${CONTAINER_REPO_HOST}/${GOOGLE_CLOUD_PROJECT}/viai-camera-integration:${VIAI_CAMERA_APP_IMAGE_TAG}/'"${CAMERA_APPLICATION_CONTAIMER_IMAGE_URL}"'/g' "$CAMERA_APPLICATION_YAML_PATH"
  sed -i 's/${CONTAINER_REPO_HOST}/${CONTAINER_REPO_REPOSITORY_NAME}/viai-camera-integration:${VIAI_CAMERA_APP_IMAGE_TAG}/'"${CAMERA_APPLICATION_CONTAIMER_IMAGE_URL}"'/g' "$CAMERA_APPLICATION_YAML_PATH"
else
  echo "${CAMERA_APPLICATION_YAML_PATH} does not exists..."
  exit $ERR_ARGUMENT_EVAL_ERROR
fi
