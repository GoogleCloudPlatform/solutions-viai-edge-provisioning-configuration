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

ANTHOS_MEMBERSHIP_NAME_DESCRIPTION="name of the memnership register to Anthos"
K8S_RUNTIME_DESCRIPTION="name of kubernetes runtime."

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script deploys VIAI Applications."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "  -k $(is_linux && echo "| --k8s-runtime"): ${K8S_RUNTIME_DESCRIPTION}"
  echo "  -m $(is_linux && echo "| --membership"): ${ANTHOS_MEMBERSHIP_NAME_DESCRIPTION}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,k8s-runtime:,membership:"
SHORT_OPTIONS="hk:m:"

ANTHOS_MEMBERSHIP_NAME=
# shellcheck disable=SC2034
K8S_RUNTIME=

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
  -k | --k8s-runtime)
    # For Interface compatibility
    # shellcheck disable=SC2034
    K8S_RUNTIME="${2}"
    shift 2
    ;;
  -m | --membership)
    ANTHOS_MEMBERSHIP_NAME="${2}"
    shift 2
    ;;
  --)
    break
    ;;
  -h | --help)
    usage
    # Ignoring because those are defined in common.sh, and don't need quotes
    # shellcheck disable=SC2086
    exit $EXIT_OK
    break
    ;;
  esac
done

check_exec_dependency "hostname"
echo "Deploying VIAI applications."

KUBECONFIG_PATH=/var/lib/viai/bmctl-workspace/${ANTHOS_MEMBERSHIP_NAME}/${ANTHOS_MEMBERSHIP_NAME}-kubeconfig

echo "[Installation] Installing dependencies..."
. "${WORKING_DIRECTORY}/scripts/machine-install-prerequisites.sh"

if [ ! -f "${KUBECONFIG_PATH}" ]; then
  echo "[Error]Unable to locate KUBECONFIG file at ${KUBECONFIG_PATH}"
  echo "       If you haven't run Anthos Bare Metal setup, please set up Anthos Bare Metal before running this script."
  # Ignoring because those are defined in common.sh, and don't need quotes
  # shellcheck disable=SC2086
  exit ${EXIT_GENERIC_ERR}
fi

if [ -z "${ANTHOS_MEMBERSHIP_NAME}" ]; then
  echo "Does not specify --membership, using hostname [$(hostname)] as Anthos Bare Metal membership name."
  ANTHOS_MEMBERSHIP_NAME=$(hostname)
fi

echo "Install VIAI Edge application"

KUBE_MENIFEST_FOLDER="${WORKING_DIRECTORY}/kubernetes"

echo "kubectl apply..."
apply_kubernetes_menifest "${KUBE_MENIFEST_FOLDER}/namespace.yaml" "${KUBECONFIG_PATH}"
apply_kubernetes_menifest "${KUBE_MENIFEST_FOLDER}/secret_image_pull.yaml" "${KUBECONFIG_PATH}"
apply_kubernetes_menifest "${KUBE_MENIFEST_FOLDER}/secret_pubsub.yaml" "${KUBECONFIG_PATH}"
apply_kubernetes_menifest "${KUBE_MENIFEST_FOLDER}/mosquitto.yaml" "${KUBECONFIG_PATH}"
apply_kubernetes_menifest "${KUBE_MENIFEST_FOLDER}/viai-camera-integration.yaml" "${KUBECONFIG_PATH}"
echo "[Installation] Completed."
