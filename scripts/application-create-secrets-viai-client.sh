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

LONG_OPTIONS="help,output-path:,service-account-key-path:"
SHORT_OPTIONS="hk:o:"

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
  -o | --output-path)
    DEPLOYMENT_TEMP_FOLDER="${2}"
    shift 2
    ;;
  -k | --service-account-key-path)
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
    ;;
  esac
done

echo "Updating Google Cloud Credentials..."
cp "${WORKING_DIRECTORY}/kubernetes/viai-camera-integration/secret_pubsub.yaml.tmpl" "$DEPLOYMENT_TEMP_FOLDER/secret_pubsub.yaml"

if [ -f "${SERVICE_ACCOUNT_KEY_PATH}" ]; then
  echo "Updating Pub/Sub credential..."
  SECRET_JSON_PATH="${SERVICE_ACCOUNT_KEY_PATH}"
  base64_encode "$SECRET_JSON_PATH" "$SECRET_JSON_PATH.tmp"
  tr -d '\n' <"$SECRET_JSON_PATH.tmp" >"$SECRET_JSON_PATH.txt"

  GCLOUD_CREDENTIAL=$(cat "$SECRET_JSON_PATH.txt")

  # This is an environment variable and a template variable, use single quota to avoid replacment
  # shellcheck disable=SC2016
  replace_variables_in_template 's/${GCLOUD_CREDENTIAL}/'"${GCLOUD_CREDENTIAL}"'/g' "$DEPLOYMENT_TEMP_FOLDER/secret_pubsub.yaml"

  rm -rf "$SECRET_JSON_PATH.txt"
  rm -rf "$SECRET_JSON_PATH.tmp"

  echo "Update completed."
else
  echo "${SERVICE_ACCOUNT_KEY_PATH} does not exists"
  # Ignoring because those are defined in common.sh, and don't need quotes
  # shellcheck disable=SC2086
  exit $ERR_MISSING_DEPENDENCY
fi
