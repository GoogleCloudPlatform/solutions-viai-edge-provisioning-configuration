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

current_file="${PWD}/${0}"
SCRIPT_EXECUTION_FOLDER="${current_file%/*}"

# shellcheck disable=SC1091
. "${SCRIPT_EXECUTION_FOLDER}/../../scripts/common.sh"

# Doesn't follow symlinks, but it's likely expected for most users
SCRIPT_BASENAME="$(basename "${0}")"

GOOGLE_CLOUD_DEFAULT_USER_EMAIL_DESC="Email of the user who has read and write access to Cloud Source Repository."
GOOGLE_CLOUD_DEFAULT_USER_ID_DESC="Id of the user who has read and write access to Cloud Source Repository."
KUBERNETS_MANIFEST_FOLDER_DESC="Folder path of Kubernetes manifest files to be pushed to Cloud Source Repository."
PROJECT_ID_DESC="Google Cloud Project Id."
SOURCE_BRANCH_DESC="Branch name, defaults to [main]"

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script set up Anthos Config-Sync required Source Repository and source codes."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -b $(is_linux && echo "| --branch"): ${SOURCE_BRANCH_DESC}"
  echo "  -i $(is_linux && echo "| --input"): ${KUBERNETS_MANIFEST_FOLDER_DESC}"
  echo "  -p $(is_linux && echo "| --project"): ${PROJECT_ID_DESC}"
  echo "  -m $(is_linux && echo "| --user-email"): ${GOOGLE_CLOUD_DEFAULT_USER_EMAIL_DESC}"
  echo "  -u $(is_linux && echo "| --user-id"): ${GOOGLE_CLOUD_DEFAULT_USER_ID_DESC}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,branch:,input:,project:,user-email:,user-id:"
SHORT_OPTIONS="hb:i:m:p:u:"

BRANCH=main
GOOGLE_CLOUD_DEFAULT_USER_EMAIL=
GOOGLE_CLOUD_DEFAULT_USER_ID=
KUBERNETS_MANIFEST_FOLDER=
PROJECT_ID=

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
  -b | --branch)
    BRANCH="${2}"
    shift 2
    ;;
  -i | --input)
    KUBERNETS_MANIFEST_FOLDER="${2}"
    shift 2
    ;;
  -p | --project)
    PROJECT_ID="${2}"
    shift 2
    ;;
  -m | --user-email)
    GOOGLE_CLOUD_DEFAULT_USER_EMAIL="${2}"
    shift 2
    ;;
  -u | --user-id)
    GOOGLE_CLOUD_DEFAULT_USER_ID="${2}"
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

check_argument "${BRANCH}" "${SOURCE_BRANCH_DESC}"
check_argument "${KUBERNETS_MANIFEST_FOLDER}" "${SOURCE_BRANCH_DESC}"
check_argument "${PROJECT_ID}" "${PROJECT_ID_DESC}"
check_argument "${GOOGLE_CLOUD_DEFAULT_USER_EMAIL}" "${GOOGLE_CLOUD_DEFAULT_USER_EMAIL_DESC}"
check_argument "${GOOGLE_CLOUD_DEFAULT_USER_ID}" "${GOOGLE_CLOUD_DEFAULT_USER_ID_DESC}"

echo "Using branch: ${BRANCH}..."

gcloud_auth

GOOGLE_APPLICATION_CREDENTIALS_PATH="/root/.config/gcloud/application_default_credentials.json"

docker run -it --rm \
  -e GOOGLE_APPLICATION_CREDENTIALS="${GOOGLE_APPLICATION_CREDENTIALS_PATH}" \
  -e PROJECT_ID="${PROJECT_ID}" \
  -e USER_EMAIL="${GOOGLE_CLOUD_DEFAULT_USER_EMAIL}" \
  -e USER_ID="${GOOGLE_CLOUD_DEFAULT_USER_ID}" \
  -e BRANCH="${BRANCH}" \
  -e GOOGLE_CLOUD_DEFAULT_USER_EMAIL="${GOOGLE_CLOUD_DEFAULT_USER_EMAIL}" \
  -v /etc/localtime:/etc/localtime:ro \
  -v "${KUBERNETS_MANIFEST_FOLDER}":/kubernetes \
  -v "${SCRIPT_EXECUTION_FOLDER}":/scripts \
  --volumes-from "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" \
  "${GCLOUD_CLI_CONTAINER_IMAGE_ID}" \
  /scripts/run.sh
