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

current_file="${PWD}/${0}"
SCRIPT_EXECUTION_FOLDER="${current_file%/*}"

# shellcheck disable=SC1091
. "$SCRIPT_EXECUTION_FOLDER/../../scripts/common.sh"

# Doesn't follow symlinks, but it's likely expected for most users
SCRIPT_BASENAME="$(basename "${0}")"

INPUT_FOLDER_DESC="folder path of deployment assets."
REMOTE_HOST_DESC="host name of the remote machine."
USER_ID_DESC="Id of the user to deploy applications, must have root access to the remote machine."

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script deploys VIAI application to remote machine via ssh."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -i $(is_linux && echo "| --input"): ${INPUT_FOLDER_DESC}"
  echo "  -t $(is_linux && echo "| --remote-host"): ${REMOTE_HOST_DESC}"
  echo "  -u $(is_linux && echo "| --remote-user"): ${USER_ID_DESC}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,input:,remote-host:,remote-user:"
SHORT_OPTIONS="hi:u:t:"

INPUT_FOLDER=
REMOTE_USER=
REMOTE_HOST=

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
  -i | --input)
    INPUT_FOLDER="${2}"
    shift 2
    ;;
  -t | --remote-host)
    REMOTE_HOST="${2}"
    shift 2
    ;;
  -u | --remote-user)
    REMOTE_USER="${2}"
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

if [ -z "${INPUT_FOLDER}" ]; then
  usage
  echo "Please specify -i $(is_linux && echo "| --input")"
  # Ignoring because those are defined in common.sh, and don't need quotes
  # shellcheck disable=SC2086
  exit ${EXIT_GENERIC_ERR}
fi

if [ -z "${REMOTE_HOST}" ]; then
  usage
  echo "Please specify -t $(is_linux && echo "| --remote-host")"
  # Ignoring because those are defined in common.sh, and don't need quotes
  # shellcheck disable=SC2086
  exit ${EXIT_GENERIC_ERR}
fi

if [ -z "${REMOTE_USER}" ]; then
  usage
  echo "Please specify -u $(is_linux && echo "| --remote-user")"
  # Ignoring because those are defined in common.sh, and don't need quotes
  # shellcheck disable=SC2086
  exit ${EXIT_GENERIC_ERR}
fi

check_exec_dependency "ssh"
check_exec_dependency "scp"

SUDO_PROMPT=$(ssh "${REMOTE_USER}"@"${REMOTE_HOST}" "sudo -nv 2>&1")

if echo "${SUDO_PROMPT}" | grep -q "sudo:"; then
  echo "User has sudo rights in remote machine..."

  WORK_DIR=$(pwd)
  cd "${INPUT_FOLDER}"
  TMP_FOLDER="/tmp"
  # shellcheck disable=SC2029
  ssh "$REMOTE_USER"@"$REMOTE_HOST" "sudo mkdir -p /var/lib/viai/; sudo mkdir -p ${TMP_FOLDER}/viai-edge-files; sudo rm -rf ${TMP_FOLDER}/viai-edge-files/*; sudo chown ""${REMOTE_USER}"" ""${TMP_FOLDER}""/viai-edge-files"

  scp -r ./* "$REMOTE_USER"@"$REMOTE_HOST":"${TMP_FOLDER}/viai-edge-files"

  # shellcheck disable=SC2029
  ssh "$REMOTE_USER"@"$REMOTE_HOST" "sudo cp -rf ${TMP_FOLDER}/viai-edge-files/* /var/lib/viai;"
  echo "Copy completed"
  ssh "$REMOTE_USER"@"$REMOTE_HOST" "sudo su; cd /var/lib/viai/; sudo bash ./scripts/0-setup-machine.sh"
  ssh "$REMOTE_USER"@"$REMOTE_HOST" "sudo su; cd /var/lib/viai/; sudo bash ./scripts/1-deploy-app.sh"
  echo "Done..."
  cd "${WORK_DIR}"
else
  echo "Use does not have sudo rights in remote machine. Cannot perfom deployment."
  exit 1
fi
