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
. ./scripts/common.sh

# Doesn't follow symlinks, but it's likely expected for most users
SCRIPT_BASENAME="$(basename "${0}")"

ANTHOS_MEMBERSHIP_NAME_DESCRIPTION="name of the memnership register to Anthos"
ANTHOS_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION="path of the anthos service account key file"
CLOUD_OPERATION_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION="Key path of Service account which has Cloud Operations roles"
CONTROL_PLANE_VIP_DESCRIPTION="control plane physical ip address, must be pingable during Anthos set up."
GCR_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION="Key path of Service account which has GCR roles"
GENERATE_ATTACH_CLUSTER_SCRIPT_DESCRIPTION="Should generate attach Anthos cluster script ? defaults to [false]"
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
  echo "  -k $(is_linux && echo "| --service-account-key-path"): ${ANTHOS_SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION}"
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

LONG_OPTIONS="help,service-account-key-path:,additional-lb-vip-range:,cloudOperationsServiceAccountKeyPath:,control-plane-vip:,default-email:,default-project:,default-region:,generate-attach-cluster-scripts,gcrKeyPath:,gkeConnectAgentServiceAccountKeyPath:,gkeConnectRegisterServiceAccountKeyPath:,ingress-vip:,k8s-runtime:,lb-vip:,membership:,output:,users:,use-physical-ip"
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

while true; do
  case "${1}" in
  -R | --additional-lb-vip-range)
    LOAD_BALANCER_VIP_RANGE="${2}"
    shift 2
    ;;
  -C | --cloudOperationsServiceAccountKeyPath)
    CLOUD_OPERATION_SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  -V | --control-plane-vip)
    CONTROL_PLANE_VIP="${2}"
    shift 2
    ;;
  -p | --default-project)
    GOOGLE_CLOUD_DEFAULT_PROJECT="${2}"
    shift 2
    ;;
  -r | --default-region)
    GOOGLE_CLOUD_DEFAULT_REGION="${2}"
    shift 2
    ;;
  -g | --generate-attach-cluster-scripts)
    # This is to determine if attach cluster script should be generated. If the customer already has Anthos cluster, or they have other Kubernete clsuter that already attached to Anthos, do not specify this flag.
    # Otherwise, specify this flag to generate scripts to attach existing cluster (or newly created cluster) to Anthos.
    # shellcheck disable=SC2034
    GENERATE_ATTACH_CLUSTER_SCRIPT="true"
    shift 1
    ;;
  -G | --gcrKeyPath)
    GCR_SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  -A | --gkeConnectAgentServiceAccountKeyPath)
    GKE_CONNECT_AGENT_SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  -S | --gkeConnectRegisterServiceAccountKeyPath)
    GKE_CONNECT_REGISTER_SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  -I | --ingress-vip)
    INGRESS_VIP="${2}"
    shift 2
    ;;
  -i | --k8s-runtime)
    K8S_RUNTIME="${2}"
    shift 2
    ;;
  -L | --lb-vip)
    LOAD_BALANCER_VIP="${2}"
    shift 2
    ;;
  -m | --membership)
    ANTHOS_MEMBERSHIP_NAME="${2}"
    shift 2
    ;;
  -o | --output)
    OUTPUT_FOLDER="${2}"
    shift 2
    ;;
  -k | --service-account-key-path)
    ANTHOS_SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  -u | --users)
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
    ;;
  esac
done

###################################################
# Anthos Set up
###################################################

DEFAULT_CONTROL_PLANE_VIP="192.168.200.170"
DEFAULT_INGRESS_VIP="192.168.200.172"
DEFAULT_LOAD_BALANCER_VIP="192.168.200.171"
DEFAULT_LOAD_BALANCER_VIP_RANGE="192.168.200.172/31"

if [ ${USE_PHYSICAL_IP} = "false" ]; then
  if ! check_optional_argument "${CONTROL_PLANE_VIP}" "${CONTROL_PLANE_VIP_DESCRIPTION}" "Use default control plane IP [${DEFAULT_CONTROL_PLANE_VIP}]"; then
    CONTROL_PLANE_VIP=${DEFAULT_CONTROL_PLANE_VIP}
  fi

  if ! check_optional_argument "${INGRESS_VIP}" "${INGRESS_VIP_DESCRIPTION}" "Use default control Ingress IP [${DEFAULT_INGRESS_VIP}]"; then
    INGRESS_VIP=${DEFAULT_INGRESS_VIP}
  fi

  if ! check_optional_argument "${LOAD_BALANCER_VIP}" "${LOAD_BALANCER_VIP_DESCRIPTION}" "Use default Load Balancer control plane IP [${DEFAULT_LOAD_BALANCER_VIP}]"; then
    LOAD_BALANCER_VIP=${DEFAULT_LOAD_BALANCER_VIP}
  fi

  if ! check_optional_argument "${LOAD_BALANCER_VIP_RANGE}" "${LOAD_BALANCER_VIP_RANGE_DESCRIPTION}" "Use default Load Balancer IP range [${DEFAULT_LOAD_BALANCER_VIP_RANGE}]"; then
    LOAD_BALANCER_VIP_RANGE=${DEFAULT_LOAD_BALANCER_VIP_RANGE}
  fi
else
  check_argument "${CONTROL_PLANE_VIP}" "${CONTROL_PLANE_VIP_DESCRIPTION}"
  check_argument "${INGRESS_VIP}" "${INGRESS_VIP_DESCRIPTION}"
  check_argument "${LOAD_BALANCER_VIP}" "${LOAD_BALANCER_VIP_DESCRIPTION}"
  check_argument "${LOAD_BALANCER_VIP_RANGE}" "${LOAD_BALANCER_VIP_RANGE_DESCRIPTION}"
fi
check_argument "${OUTPUT_FOLDER}" "${OUTPUT_FOLDER_DESCRIPTION}"

echo "cleaning existing $OUTPUT_FOLDER/edge-server/node-setup.sh"
if [ -f "$OUTPUT_FOLDER/edge-server/node-setup.sh" ]; then
  echo "Deleting $OUTPUT_FOLDER/edge-server/node-setup.sh..."
  rm -rf "$OUTPUT_FOLDER/edge-server/node-setup.sh"
fi

echo "copying init.sh.tmpl and env: ${ANTHOS_SERVICE_ACCOUNT_KEY_PATH}"
rm -rf "$OUTPUT_FOLDER/edge-server/"
mkdir -p "$OUTPUT_FOLDER/edge-server/"
mkdir -p "$OUTPUT_FOLDER/scripts/"

echo "copying Anthos-service-account-key"
cp "${GCR_SERVICE_ACCOUNT_KEY_PATH}" "$OUTPUT_FOLDER/edge-server/gcr-service-account-key.json"
cp "${GKE_CONNECT_AGENT_SERVICE_ACCOUNT_KEY_PATH}" "$OUTPUT_FOLDER/edge-server/gke-connect-angent-account-key.json"
cp "${GKE_CONNECT_REGISTER_SERVICE_ACCOUNT_KEY_PATH}" "$OUTPUT_FOLDER/edge-server/gke-connect-register-account-key.json"
cp "${CLOUD_OPERATION_SERVICE_ACCOUNT_KEY_PATH}" "$OUTPUT_FOLDER/edge-server/cloud-ops-account-key.json"

cp "${ANTHOS_SERVICE_ACCOUNT_KEY_PATH}" "$OUTPUT_FOLDER/edge-server/anthos-service-account-key.json"
cp "${WORKING_DIRECTORY}/edge-server/anthos/init.sh.tmpl" "$OUTPUT_FOLDER/edge-server/init.sh"
cp "${WORKING_DIRECTORY}/edge-server/anthos/env.sh.tmpl" "$OUTPUT_FOLDER/edge-server/env.sh"

echo "Updating init.sh...${ANTHOS_SERVICE_ACCOUNT_KEY_PATH}"
# shellcheck disable=SC2016
sed -i 's/${GOOGLE_CLOUD_DEFAULT_PROJECT}/'"${GOOGLE_CLOUD_DEFAULT_PROJECT}"'/g' "$OUTPUT_FOLDER/edge-server/init.sh"
# shellcheck disable=SC2016
sed -i 's/${GOOGLE_CLOUD_DEFAULT_REGION}/'"${GOOGLE_CLOUD_DEFAULT_REGION}"'/g' "$OUTPUT_FOLDER/edge-server/init.sh"
# shellcheck disable=SC2016
sed -i 's/${ANTHOS_SERVICE_ACCOUNT_KEY_PATH}/\/var\/lib\/viai\/setup\/edge-server\/anthos-service-account-key.json/g' "$OUTPUT_FOLDER/edge-server/init.sh"

echo "Updating env.sh..."
# shellcheck disable=SC2016
sed -i 's/${ANTHOS_VERSION}/'"${ANTHOS_VERSION}"'/g' "$OUTPUT_FOLDER/edge-server/env.sh"
# shellcheck disable=SC2016
sed -i 's/${ANTHOS_MEMBERSHIP_NAME}/'"${ANTHOS_MEMBERSHIP_NAME}"'/g' "$OUTPUT_FOLDER/edge-server/env.sh"
# shellcheck disable=SC2016
sed -i 's/${CONTROL_PLANE_VIP}/'"${CONTROL_PLANE_VIP}"'/g' "$OUTPUT_FOLDER/edge-server/env.sh"
# shellcheck disable=SC2016
sed -i 's/${INGRESS_VIP}/'"${INGRESS_VIP}"'/g' "$OUTPUT_FOLDER/edge-server/env.sh"
# shellcheck disable=SC2016
sed -i 's/${LOAD_BALANCER_VIP}/'"${LOAD_BALANCER_VIP}"'/g' "$OUTPUT_FOLDER/edge-server/env.sh"

escape_slash "${LOAD_BALANCER_VIP_RANGE}"
echo "ESCAPED_NAME=${ESCAPED_NAME}"
# shellcheck disable=SC2016
sed -i 's/${LOAD_BALANCER_VIP_RANGE}/'"${ESCAPED_NAME}"'/g' "$OUTPUT_FOLDER/edge-server/env.sh"
unset ESCAPED_NAME

echo "Updating node-setup.sh..."
cat "$OUTPUT_FOLDER/edge-server/init.sh" >>"$OUTPUT_FOLDER/edge-server/node-setup.sh"
rm -rf "$OUTPUT_FOLDER/edge-server/init.sh"

cat "$OUTPUT_FOLDER/edge-server/env.sh" >>"$OUTPUT_FOLDER/edge-server/node-setup.sh"
rm -rf "$OUTPUT_FOLDER/edge-server/env.sh"

cat "${WORKING_DIRECTORY}/edge-server/anthos/node-setup-common.sh.tmpl" >>"$OUTPUT_FOLDER/edge-server/node-setup.sh"

if [ ${USE_PHYSICAL_IP} = "false" ]; then
  cat "${WORKING_DIRECTORY}/edge-server/anthos/node-setup-vlan.tmpl" >>"$OUTPUT_FOLDER/edge-server/node-setup.sh"
else
  cat "${WORKING_DIRECTORY}/edge-server/anthos/node-setup.sh.tmpl" >>"$OUTPUT_FOLDER/edge-server/node-setup.sh"
fi

cp "${WORKING_DIRECTORY}/edge-server/anthos/bmctl-physical-template.yaml" "$OUTPUT_FOLDER/edge-server/bmctl-physical-template.yaml"

echo "Copying Anthos Bare Metal template file..."
cp "${WORKING_DIRECTORY}/edge-server/anthos/config-section.toml" "$OUTPUT_FOLDER/edge-server/config-section.toml"

echo "Copy dependecies installation scripts..."
cp "${WORKING_DIRECTORY}/scripts/machine-install-prerequisites.sh" "$OUTPUT_FOLDER/edge-server/machine-install-prerequisites.sh"
########################################################################
# Attach Cluster
########################################################################
cp "${WORKING_DIRECTORY}/edge-server/${K8S_RUNTIME}/attach-cluster.sh" "${OUTPUT_FOLDER}/scripts/"

echo "USERS_EMAILS=${USERS_EMAILS}"
# Anthos cluster creation is done in node-setup
cat <<EOF2 >"${OUTPUT_FOLDER}/scripts/0-setup-machine.sh"
#!/usr/bin/env sh

cd /var/lib/viai/
mkdir -p ./log
. /var/lib/viai/scripts/attach-cluster.sh \\
          --default-project "${GOOGLE_CLOUD_DEFAULT_PROJECT}" \\
          --k8s-runtime "${K8S_RUNTIME}" \\
          --users "${USERS_EMAILS}" \\
          --membership "${ANTHOS_MEMBERSHIP_NAME}" \\
          2>&1 | tee ./log/attach-cluster.log
EOF2

echo "Node setup scripts have been generated at ${OUTPUT_FOLDER}/edge-server"
