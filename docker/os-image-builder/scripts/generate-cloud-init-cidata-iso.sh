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

echo "This script has been invoked with: $0 $*"

# shellcheck disable=SC1094
. scripts/common.sh

# Doesn't follow symlinks, but it's likely expected for most users
SCRIPT_BASENAME="$(basename "${0}")"

EDGE_CONFIG_DIRECTORY_PATH_DESCRIPTION="Path to the Edge server configuration files"
K8S_RUNTIME_DESCRIPTION="kubernetes runtime, can be [anthos], [microk8s] or [k3s]"

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script generates the CIDATA ISO."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -d $(is_linux && echo "| --edge-config-directory-path"): ${EDGE_CONFIG_DIRECTORY_PATH_DESCRIPTION}"
  echo "  -i $(is_linux && echo "| --k8s-runtime"): ${K8S_RUNTIME_DESCRIPTION}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,edge-config-directory-path:,k8s-runtime:"
SHORT_OPTIONS="hd:i:"

EDGE_CONFIG_DIRECTORY_PATH=
K8S_RUNTIME=

echo "Checking if the necessary dependencies are available..."
check_exec_dependency "cp"
check_exec_dependency "docker"
check_exec_dependency "getopt"
check_exec_dependency "rm"

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
  -d | --edge-config-directory-path)
    EDGE_CONFIG_DIRECTORY_PATH="${2}"
    shift 2
    ;;
  -i | --k8s-runtime)
    K8S_RUNTIME="${2}"
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
    exit ${EXIT_OK}
    ;;
  esac
done

############ Start ABM Prep ######################
echo "EDGE_CONFIG_DIRECTORY_PATH=${EDGE_CONFIG_DIRECTORY_PATH}"

if [ ! -f "${EDGE_CONFIG_DIRECTORY_PATH}/service-account-key.json" ]; then
  echo "Service account key file does not exist, please run terraform to create the service account and download JSON key file to ${WORKING_DIRECTORY}/tmp/."
  exit 1
fi

echo "cp ${WORKING_DIRECTORY}/media/USB/${K8S_RUNTIME}/meta-data.yaml ${EDGE_CONFIG_DIRECTORY_PATH}/..."
cp "${WORKING_DIRECTORY}/media/USB/${K8S_RUNTIME}/meta-data.yaml" "${EDGE_CONFIG_DIRECTORY_PATH}/"
echo "cp ${WORKING_DIRECTORY}/media/USB/${K8S_RUNTIME}/user-data.yaml ${EDGE_CONFIG_DIRECTORY_PATH}/..."
cp "${WORKING_DIRECTORY}/media/USB/${K8S_RUNTIME}/user-data.yaml" "${EDGE_CONFIG_DIRECTORY_PATH}/"

VIAI_INSTALLER_CONFIGURATION_DATA_ISO_DIRECTORY_PATH="$(mktemp -d)"
echo "Building the OS image builder container image..."
docker build -t os-image-builder "$(pwd)/docker/os-image-builder"

echo "Creating the CIDATA ISO in ${VIAI_INSTALLER_CONFIGURATION_DATA_ISO_DIRECTORY_PATH}..."

docker run \
  -v "${EDGE_CONFIG_DIRECTORY_PATH}":/tmp/cloud-init-source \
  -v "${VIAI_INSTALLER_CONFIGURATION_DATA_ISO_DIRECTORY_PATH}":/tmp/cloud-init-output \
  os-image-builder:latest \
  -d /tmp/cloud-init-source \
  -oy /tmp/cloud-init-output

echo "CIDATA ISO file created successfully, folder path: ${VIAI_INSTALLER_CONFIGURATION_DATA_ISO_DIRECTORY_PATH} , file name: cloud-init-datasource.iso"

trap 'echo "Cleaning up..."; rm -fr "${EDGE_CONFIG_DIRECTORY_PATH_DESCRIPTION}"; ' EXIT
