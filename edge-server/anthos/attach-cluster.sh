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
GENERATE_ATACH_CLUSTER_SCRIPT_DESCRIPTION="should generate scripts to attach clusters."
GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION="name of the default Google Cloud Project to use"
K8S_RUNTIME_NAME_DESCRIPTION="name of kubernetes runtime."
SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION="path of service account key file."
USER_EMAILS_DESCRIPTION="email addresses to grant cluster RBAC roles, split by common, for example, user1@domain.com,user2.domain.com"

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script binds RBAC role for GKE connect gateway."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -p $(is_linux && echo "| --default-project"): ${GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION}"
  echo "  -g $(is_linux && echo "| --generate-attach-cluster-scripts"): ${GENERATE_ATACH_CLUSTER_SCRIPT_DESCRIPTION}"
  echo "  -i $(is_linux && echo "| --k8s-runtime"): ${K8S_RUNTIME_NAME_DESCRIPTION}"
  echo "  -m $(is_linux && echo "| --membership"): ${ANTHOS_MEMBERSHIP_NAME_DESCRIPTION}"
  echo "  -k $(is_linux && echo "| --service-account-key-path"): ${SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION}"
  echo "  -u $(is_linux && echo "| --users"): ${USER_EMAILS_DESCRIPTION}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,default-project:,generate-attach-cluster-scripts,k8s-runtime:,membership:,service-account-key-path:,users:"
SHORT_OPTIONS="hg:i:k:m:p:u:"

ANTHOS_MEMBERSHIP_NAME=
GENERATE_ATACH_CLUSTER_SCRIPT="false" # This flag is unused in Anthos, it's for interface compatibility
GOOGLE_CLOUD_PROJECT=
K8S_RUNTIME=
KUBECONFIG_PATH=
KUBECONFIG_CONTEXT_NAME=
SERVICE_ACCOUNT_KEY_PATH=$(pwd)/service-account-key.json
USERS_EMAILS=

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
  -p | --default-project)
    GOOGLE_CLOUD_PROJECT="${2}"
    shift 2
    ;;
  -g | --generate-attach-cluster-scripts)
    # This is for interface compatibility
    # shellcheck disable=SC2034
    GENERATE_ATACH_CLUSTER_SCRIPT="true"
    shift 1
    ;;
  -i | --k8s-runtime)
    # This is for interface compatibility
    # shellcheck disable=SC2034
    K8S_RUNTIME="${2}"
    shift 2
    ;;
  -m | --membership)
    ANTHOS_MEMBERSHIP_NAME="${2}"
    shift 2
    ;;
  -k | --service-account-key-path)
    SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  -u | --users)
    USERS_EMAILS="${2}"
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

check_exec_dependency "hostname"
check_exec_dependency "gcloud"

echo "Edge Server Set up"
if ! check_optional_argument "${ANTHOS_MEMBERSHIP_NAME}" "${ANTHOS_MEMBERSHIP_NAME_DESCRIPTION}" "Use hostname [$(hostname)] as Anthos Bare Metal membership name."; then
  ANTHOS_MEMBERSHIP_NAME=$(hostname)
fi

echo "Anthos membership is ${ANTHOS_MEMBERSHIP_NAME}"
KUBECONFIG_PATH="/var/lib/viai/bmctl-workspace/${ANTHOS_MEMBERSHIP_NAME}/${ANTHOS_MEMBERSHIP_NAME}-kubeconfig"

echo "Anthos Bare Metal Kubeconfig path is ${KUBECONFIG_PATH}"
KUBECONFIG_CONTEXT_NAME=${ANTHOS_MEMBERSHIP_NAME}-admin@${ANTHOS_MEMBERSHIP_NAME}

echo "[Installation] Installing dependencies..."
. ./scripts/machine-install-prerequisites.sh

if [ ! -f "${KUBECONFIG_PATH}" ]; then
  echo "[Error]Unable to locate KUBECONFIG file at ${KUBECONFIG_PATH}, If you haven't run Anthos Bare Metal setup, please set up Anthos Bare Metal before running this script."
  # Ignoring because those are defined in common.sh, and don't need quotes
  # shellcheck disable=SC2086
  exit ${EXIT_GENERIC_ERR}
fi

# Activate service account
echo "SERVICE_ACCOUNT_KEY_PATH=${SERVICE_ACCOUNT_KEY_PATH}"
gcloud auth activate-service-account --key-file="${SERVICE_ACCOUNT_KEY_PATH}"

echo "Creating RBAC for Connect Gateway..."

gcloud beta container fleet memberships generate-gateway-rbac \
  --membership="${ANTHOS_MEMBERSHIP_NAME}" \
  --role=clusterrole/cluster-admin \
  --users="${USERS_EMAILS}" \
  --kubeconfig="${KUBECONFIG_PATH}" \
  --context="${KUBECONFIG_CONTEXT_NAME}" \
  --project "${GOOGLE_CLOUD_PROJECT}" \
  --apply

# grant service account the same cluster role so it has permissions to deploy containers via Cloud Deploy
gcloud beta container fleet memberships generate-gateway-rbac \
  --membership="${ANTHOS_MEMBERSHIP_NAME}" \
  --role=clusterrole/cluster-admin \
  --users="$(gcloud config get account)" \
  --kubeconfig="${KUBECONFIG_PATH}" \
  --context="${KUBECONFIG_CONTEXT_NAME}" \
  --project "${GOOGLE_CLOUD_PROJECT}" \
  --apply

echo "[Installation] Completed."
