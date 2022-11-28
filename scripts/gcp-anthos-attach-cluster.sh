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
GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION="name of the default Google Cloud Project to use"
KUBECONFIG_PATH_DESCRIPTION="path of kubeconfig file"
KUBECONFIG_CONTEXT_NAME_DESCRIPTION="name of the kubeconfig context"
SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION="path of the service account key file"
USER_EMAILS_DESCRIPTION="email addresses to grant cluster RBAC roles, split by common, for example, [user1@domain.com,user2.domain.com]"

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script attach k8s clusters to Anthos"
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "       $(is_linux && echo "--default-project"): ${GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION}"
  echo "       $(is_linux && echo "--service-account-key-path"): ${SERVICE_ACCOUNT_KEY_PATH_DESCRIPTION}"
  echo "       $(is_linux && echo "--kubeconfig-path"): ${KUBECONFIG_PATH_DESCRIPTION}"
  echo "       $(is_linux && echo "--kubeconfig-context"): ${KUBECONFIG_CONTEXT_NAME_DESCRIPTION}"
  echo "       $(is_linux && echo "--users"): ${USER_EMAILS_DESCRIPTION}"
  echo "       $(is_linux && echo "--membership"): ${ANTHOS_MEMBERSHIP_NAME_DESCRIPTION}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,service-account-key-path:,default-project:,kubeconfig-path:,kubeconfig-context:,membership:,users:"
SHORT_OPTIONS="h"

ANTHOS_MEMBERSHIP_NAME=
GOOGLE_CLOUD_PROJECT=
KUBECONFIG_PATH=
KUBECONFIG_CONTEXT_NAME=
SERVICE_ACCOUNT_KEY_PATH=
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
  case "${1-default}" in
  --service-account-key-path)
    SERVICE_ACCOUNT_KEY_PATH="${2}"
    shift 2
    ;;
  --default-project)
    GOOGLE_CLOUD_PROJECT="${2}"
    shift 2
    ;;
  --kubeconfig-path)
    KUBECONFIG_PATH="${2}"
    shift 2
    ;;
  --kubeconfig-context)
    KUBECONFIG_CONTEXT_NAME="${2}"
    shift 2
    ;;
  --membership)
    ANTHOS_MEMBERSHIP_NAME="${2}"
    shift 2
    ;;
  --users)
    # Reserved for different Kubernetes runtime, ex, Anthos or Microk8s
    # shellcheck disable=SC2034
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

gcloud auth activate-service-account --key-file="${SERVICE_ACCOUNT_KEY_PATH}"
if ! check_optional_argument "${ANTHOS_MEMBERSHIP_NAME}" "${ANTHOS_MEMBERSHIP_NAME_DESCRIPTION}" "Use hostname [$(hostname)] as Anthos Bare Metal membership name."; then
  ANTHOS_MEMBERSHIP_NAME=$(hostname)
fi

gcloud container hub memberships register "${ANTHOS_MEMBERSHIP_NAME}" \
  --context="${KUBECONFIG_CONTEXT_NAME}" \
  --kubeconfig="${KUBECONFIG_PATH}" \
  --has-private-issuer \
  --enable-workload-identity \
  --project "${GOOGLE_CLOUD_PROJECT}"
