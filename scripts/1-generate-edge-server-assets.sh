#!/usr/bin/env sh

# Copyright 2021 Google LLC
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

. scripts/common.sh

# Doesn't follow symlinks, but it's likely expected for most users
SCRIPT_BASENAME="$(basename "${0}")"

ANTHOS_MEMBERSHIP_NAME_DESCRIPTION="name of the memnership register to Anthos"
ANTHOS_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION="path of the anthos service account key file"
CLOUD_OPERATION_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION="Key path of Service account which has Cloud Operations roles"
CONTROL_PLANE_VIP_DESCRIPTION="control plane physical ip address, must be pingable during Anthos set up."
GCR_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION="Key path of Service account which has GCR roles"
GENERATE_ATTACH_CLUSTER_SCRIPT_DESCRIPTION="Shoud generate attach Anthos cluster script ? defaults to [false]"
GKE_CONNECT_AGENT_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION="Key path of Service account which has GKE connect agent roles"
GKE_CONNECT_REGISTER_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION="Key path of Service account which has GKE connect register roles"
GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION="name of the default Google Cloud Project to use"
GOOGLE_CLOUD_DEFAULT_REGION_DESCRIPTION="ID of the default Google Cloud Region to use"
INGRESS_VIP_DESCRIPTION="Ingress VIP, MUST be in CONTROL_PLANE_VIP/24 and NOT pingable during Anthos set up."
K8S_RUNTIME_DESCRIPTION="kubernetes runtime, can be [anthos], [microk8s] or [k3s]"
LOAD_BALANCER_VIP_DESCRIPTION="Load Balancer VIP, MUST be in CONTROL_PLANE_VIP/24 and NOT pingable during Anthos set up."
LOAD_BALANCER_VIP_RANGE_DESCRIPTION="Load Balancer VIP range, will be used to create additional load balancer, MUST be in CONTROL_PLANE_VIP/24 and NOT pingable during Anthos set up."
OUTPUT_FOLDER_DESCRIPTION="output folder path"
USER_EMAILS_DESCRIPTION="email addresses to grant cluster RBAC roles, split by common, for example, [user1@domain.com,user2.domain.com]"
USE_PHYSICAL_IP_DESCRIPTION="Use physical network IP addresses to set up Anthos bare metal, if this flag is not set, will set up vxlan, which is the default."

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script initializes Anthos Bare Metal set up assets."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -k $(is_linux && echo "| --service-account-key-path"): ${ANTHOS_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION}"
  echo "  -R $(is_linux && echo "| --additional-lb-vip-range"): ${LOAD_BALANCER_VIP_RANGE_DESCRIPTION}"
  echo "  -C $(is_linux && echo "| --cloudOperationsServiceAccountKeyPath"): ${CLOUD_OPERATION_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION}"
  echo "  -V $(is_linux && echo "| --control-plane-vip"): ${CONTROL_PLANE_VIP_DESCRIPTION}"
  echo "  -p $(is_linux && echo "| --default-project"): ${GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION}"
  echo "  -r $(is_linux && echo "| --default-region"): ${GOOGLE_CLOUD_DEFAULT_REGION_DESCRIPTION}"
  echo "  -G $(is_linux && echo "| --gcrKeyPath"): ${GCR_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION}"
  echo "  -g $(is_linux && echo "| --generate-attach-cluster-scripts"): ${GENERATE_ATTACH_CLUSTER_SCRIPT_DESCRIPTION}"
  echo "  -A $(is_linux && echo "| --gkeConnectAgentServiceAccountKeyPath"): ${GKE_CONNECT_AGENT_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION}"
  echo "  -S $(is_linux && echo "| --gkeConnectRegisterServiceAccountKeyPath"): ${GKE_CONNECT_REGISTER_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION}"
  echo "  -I $(is_linux && echo "| --ingress-vip"): ${INGRESS_VIP_DESCRIPTION}"
  echo "  -i $(is_linux && echo "| --k8s-runtime"): ${K8S_RUNTIME_DESCRIPTION}"
  echo "  -L $(is_linux && echo "| --lb-vip"): ${LOAD_BALANCER_VIP_DESCRIPTION}"
  echo "  -m $(is_linux && echo "| --membership"): ${ANTHOS_MEMBERSHIP_NAME_DESCRIPTION}"
  echo "  -o $(is_linux && echo "| --output"): ${OUTPUT_FOLDER_DESCRIPTION}"
  echo "  -u $(is_linux && echo "| --users"): ${USER_EMAILS_DESCRIPTION}"
  echo "  -x $(is_linux && echo "| --use-physical-ip"): ${USE_PHYSICAL_IP_DESCRIPTION}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,service-account-key-path:,additional-lb-vip-range:,cloudOperationsServiceAccountKeyPath:,control-plane-vip:,default-email:,default-project:,default-region:,default-zone:,generate-attach-cluster-scripts,gcrKeyPath:,gkeConnectAgentServiceAccountKeyPath:,gkeConnectRegisterServiceAccountKeyPath:,ingress-vip:,k8s-runtime:,lb-vip:,membership:,output:,users:,use-physical-ip"
SHORT_OPTIONS="ghxA:C:I:L:G:R:S:V:i:k:m:o:p:r:u:"

ANTHOS_MEMBERSHIP_NAME=
ANTHOS_SERVICE_ACCOUNT_KEY_PATH=
CLOUD_OPERATION_SERVICE_ACCOUNT_KEY_PATH=
CONTROL_PLANE_VIP=
GCR_SERVICE_ACCOUNT_KEY_PATH=
GENERATE_ATTACH_CLUSTER_SCRIPT="false"
GKE_CONNECT_AGENT_SERVICE_ACCOUNT_KEY_PATH=
GKE_CONNECT_REGISTER_SERVICE_ACCOUNT_KEY_PATH=
GOOGLE_CLOUD_DEFAULT_PROJECT=
GOOGLE_CLOUD_DEFAULT_REGION=
INGRESS_VIP=
K8S_RUNTIME=
LOAD_BALANCER_VIP=
LOAD_BALANCER_VIP_RANGE=
OUTPUT_FOLDER=
USERS_EMAILS=
USE_PHYSICAL_IP="false"

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

# This is an array, not string, do not quote it
# shellcheck disable=SC2086
ARGUMENTS=$*

# Variables are required for different kubernetes runtime, for exampl, Anthos may required LOAD_BALANCER_VIP_RANGE while others are not.
while true; do
  case "${1}" in
  -R | --additional-lb-vip-range)
    # shellcheck disable=SC2034
    LOAD_BALANCER_VIP_RANGE="${2}"
    shift 2
    ;;
  -C | --cloudOperationsServiceAccountKeyPath)
    # shellcheck disable=SC2034
    CLOUD_OPERATION_SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  -V | --control-plane-vip)
    # shellcheck disable=SC2034
    CONTROL_PLANE_VIP="${2}"
    shift 2
    ;;
  -p | --default-project)
    # shellcheck disable=SC2034
    GOOGLE_CLOUD_DEFAULT_PROJECT="${2}"
    shift 2
    ;;
  -r | --default-region)
    # shellcheck disable=SC2034
    GOOGLE_CLOUD_DEFAULT_REGION="${2}"
    shift 2
    ;;
  -g | --generate-attach-cluster-scripts)
    # shellcheck disable=SC2034
    GENERATE_ATTACH_CLUSTER_SCRIPT="true"
    shift 1
    ;;
  -G | --gcrKeyPath)
    # shellcheck disable=SC2034
    GCR_SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  -A | --gkeConnectAgentServiceAccountKeyPath)
    # shellcheck disable=SC2034
    GKE_CONNECT_AGENT_SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  -S | --gkeConnectRegisterServiceAccountKeyPath)
    # shellcheck disable=SC2034
    GKE_CONNECT_REGISTER_SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  -I | --ingress-vip)
    # shellcheck disable=SC2034
    INGRESS_VIP="${2}"
    shift 2
    ;;
  -i | --k8s-runtime)
    # shellcheck disable=SC2034
    K8S_RUNTIME="${2}"
    shift 2
    ;;
  -L | --lb-vip)
    # shellcheck disable=SC2034
    LOAD_BALANCER_VIP="${2}"
    shift 2
    ;;
  -m | --membership)
    # shellcheck disable=SC2034
    ANTHOS_MEMBERSHIP_NAME="${2}"
    shift 2
    ;;
  -o | --output)
    # shellcheck disable=SC2034
    OUTPUT_FOLDER="${2}"
    shift 2
    ;;
  -k | --service-account-key-path)
    # shellcheck disable=SC2034
    ANTHOS_SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  -u | --users)
    # shellcheck disable=SC2034
    USERS_EMAILS="${2}"
    shift 2
    ;;
  -x | --use-physical-ip)
    # shellcheck disable=SC2034
    USE_PHYSICAL_IP="true"
    shift
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

if [ ! -f "$(pwd)/edge-server/${K8S_RUNTIME}/generate-script.sh" ]; then
  echo "[ERROR] Required scripts for Kubternetes runtime [${K8S_RUNTIME}] not found."
  # Ignoring because those are defined in common.sh, and don't need quotes
  # shellcheck disable=SC2086
  exit $EXIT_GENERIC_ERR
fi

if [ "${K8S_RUNTIME}" = "anthos" ] && [ ${USE_PHYSICAL_IP} = "true" ]; then
  check_argument "${CONTROL_PLANE_VIP}" "${CONTROL_PLANE_VIP_DESCRIPTION}"
  check_argument "${INGRESS_VIP}" "${INGRESS_VIP_DESCRIPTION}"
  check_argument "${LOAD_BALANCER_VIP}" "${LOAD_BALANCER_VIP_DESCRIPTION}"
  check_argument "${LOAD_BALANCER_VIP_RANGE}" "${LOAD_BALANCER_VIP_RANGE_DESCRIPTION}"
fi

check_argument "${USERS_EMAILS}" "${USER_EMAILS_DESCRIPTION}"
check_argument "${OUTPUT_FOLDER}" "${OUTPUT_FOLDER_DESCRIPTION}"

# shellcheck disable=SC2240,SC1090,SC2086
. "${WORKING_DIRECTORY}"/edge-server/"${K8S_RUNTIME}"/generate-script.sh ${ARGUMENTS}
