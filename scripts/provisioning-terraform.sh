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

ANTHOS_TARGET_CLUSTER_MEMBERSHIP_DESCRIPTION="Anthos Membership name of the target environment."
AUTHENTICATE_GOOGLE_CLOUD_DESCRIPTION="Authenticate a Google account for Google Cloud"
GENERATE_TFVARS_FILE_DESCRIPTION="Generate terraform.tfvars"
GOOGLE_CLOUD_DEFAULT_USER_EMAIL_DESCRIPTION="User email, this user will be granted permissions in Anthos cluster and GCP resources to manage and operate Anthos."
GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION="name of the default Google Cloud Project to use"
GOOGLE_CLOUD_DEFAULT_REGION_DESCRIPTION="ID of the default Google Cloud Region to use"
GOOGLE_CLOUD_DEFAULT_ZONE_DESCRIPTION="ID of the default Google Cloud Zone to use"
GOOGLE_CLOUD_VIAI_STORAGE_BUCKET_LOCATION_DESCRIPTION="Location where to create VIAI storage buckets"
TERRAFORM_SUBCOMMAND_DESCRIPTION="Terraform subcommand to run, along with arguments. Defaults to apply."
SANDBOX_DESCRIPTION="Enable provisioning of a GCE VM to use as a sandbox?"

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script initializes the environment for Terraform, and runs it. The script will always run terraform init and terraform validate before any subcommand you specify."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -a $(is_linux && echo "| --authenticate-google-cloud"): ${AUTHENTICATE_GOOGLE_CLOUD_DESCRIPTION}"
  echo "  -p $(is_linux && echo "| --default-project"): ${GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION}"
  echo "  -r $(is_linux && echo "| --default-region"): ${GOOGLE_CLOUD_DEFAULT_REGION_DESCRIPTION}"
  echo "  -z $(is_linux && echo "| --default-zone"): ${GOOGLE_CLOUD_DEFAULT_ZONE_DESCRIPTION}"
  echo "  -m $(is_linux && echo "| --default-email"): ${GOOGLE_CLOUD_DEFAULT_USER_EMAIL_DESCRIPTION}"
  echo "  -g $(is_linux && echo "| --generate-tfvars"): ${GENERATE_TFVARS_FILE_DESCRIPTION}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo "  -e $(is_linux && echo "| --membership"): ${ANTHOS_TARGET_CLUSTER_MEMBERSHIP_DESCRIPTION}"
  echo "  -x $(is_linux && echo "| --sandbox"): ${SANDBOX_DESCRIPTION}"
  echo "  -l $(is_linux && echo "| --storage-bucket-location"): ${GOOGLE_CLOUD_VIAI_STORAGE_BUCKET_LOCATION_DESCRIPTION}"
  echo "  -s $(is_linux && echo "| --terraform-subcommand"): ${TERRAFORM_SUBCOMMAND_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="authenticate-google-cloud,default-project:,default-region:,default-zone:,default-email:,generate-tfvars,git-repo-url:,git-repo-branch:,help,membership:,sandbox,storage-bucket-location:,terraform-subcommand:"
SHORT_OPTIONS="aghxe:l:p:r:s:m:z:"

echo "Checking if the necessary dependencies are available..."
check_exec_dependency "docker"
check_exec_dependency "getopt"
check_exec_dependency "sed"
check_exec_dependency "tee"

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

ANTHOS_TARGET_CLUSTER_MEMBERSHIP=
AUTHENTICATE_GOOGLE_CLOUD="false"
GENERATE_TFVARS_FILE="false"
GOOGLE_CLOUD_DEFAULT_PROJECT=
GOOGLE_CLOUD_DEFAULT_REGION=
GOOGLE_CLOUD_DEFAULT_ZONE=
GOOGLE_CLOUD_VIAI_STORAGE_BUCKET_LOCATION=
GOOGLE_CLOUD_DEFAULT_USER_EMAIL=
TERRAFORM_SUBCOMMAND="apply"
SANDBOX="false"

while true; do
  case "${1}" in
  -a | --authenticate-google-cloud)
    AUTHENTICATE_GOOGLE_CLOUD="true"
    shift
    ;;
  -m | --default-email)
    GOOGLE_CLOUD_DEFAULT_USER_EMAIL="${2}"
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
  -z | --default-zone)
    GOOGLE_CLOUD_DEFAULT_ZONE="${2}"
    shift 2
    ;;
  -g | --generate-tfvars)
    GENERATE_TFVARS_FILE="true"
    shift
    ;;
  -e | --membership)
    ANTHOS_TARGET_CLUSTER_MEMBERSHIP="${2}"
    shift 2
    ;;
  -l | --storage-bucket-location)
    GOOGLE_CLOUD_VIAI_STORAGE_BUCKET_LOCATION="${2}"
    shift 2
    ;;
  -s | --terraform-subcommand)
    TERRAFORM_SUBCOMMAND="${2}"
    shift 2
    ;;
  -x | --sandbox)
    SANDBOX="true"
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

check_optional_argument "${AUTHENTICATE_GOOGLE_CLOUD}" "${AUTHENTICATE_GOOGLE_CLOUD_DESCRIPTION}"
check_optional_argument "${TERRAFORM_SUBCOMMAND}" "${TERRAFORM_SUBCOMMAND_DESCRIPTION}"
check_optional_argument "${GENERATE_TFVARS_FILE}" "${GENERATE_TFVARS_FILE_DESCRIPTION}"

gcloud_auth

CURRENT_WORKING_DIRECTORY="$(pwd)"
TERRAFORM_ENVIRONMENT_DIR="${CURRENT_WORKING_DIRECTORY}/terraform"
TERRAFORM_TFVARS_PATH="${TERRAFORM_ENVIRONMENT_DIR}/terraform.tfvars"

# "${HOME}"/.config/gcloud/application_default_credentials.json is a well-known location for application-default credentials
GOOGLE_APPLICATION_CREDENTIALS_PATH="/root/.config/gcloud/application_default_credentials.json"

###### Cloud Functions ######
VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH="$(mktemp -d)"
mkdir -p "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}/gcf"

if [ "${TERRAFORM_SUBCOMMAND}" != "destroy" ]; then
  # Create Storage Bucket for Terraform states
  RUNTIME_SCRIPT_FOLDER="$(mktemp -d)"

  cat <<EOF >"${RUNTIME_SCRIPT_FOLDER}/run.sh"
if ! gsutil list -p "${DEFAULT_PROJECT}" | grep "gs://tf-state-${DEFAULT_PROJECT}/" ; then
  echo "Terraform backend storage does not exists, creating..."
  gsutil mb -p ${DEFAULT_PROJECT} gs://tf-state-${DEFAULT_PROJECT}
else
  echo "Terraform backend exists, skip..."
fi
EOF
  gcloud_exec_scripts "${GOOGLE_APPLICATION_CREDENTIALS_PATH}" "${RUNTIME_SCRIPT_FOLDER}" "run.sh"

  # Download and build Cloud Functions source codes
  ZIP_FILE_NAME="cloudfunction-$(date +%Y%m%d-%H%M%S).zip"

  echo "Copy Cloud Functions code..."
  cp -rf "${WORKING_DIRECTORY}/terraform/files/gcf-pubsub-to-bq/" "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}/gcf"

  echo "Archiving source codes..."
  zip -r -j "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}/${ZIP_FILE_NAME}" "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}/gcf"
  VIAI_CAMERA_INTEGRATION_FILE_PATH="/packages/${ZIP_FILE_NAME}" # Containerized Terraform working directory
  echo "Containerized Zip file path: ${VIAI_CAMERA_INTEGRATION_FILE_PATH}"

  ### Update Artifact Registry list
  TF_VAR_ANTHOS_TARGET_CLUSTER_MEMBERSHIP_NAMES=
  IFS=","
  if [ -n "${ANTHOS_TARGET_CLUSTER_MEMBERSHIP}" ]; then
    for MEMBERSHIP in $ANTHOS_TARGET_CLUSTER_MEMBERSHIP; do
      echo "Adding ${MEMBERSHIP}..."
      if [ -z "${TF_VAR_ANTHOS_TARGET_CLUSTER_MEMBERSHIP_NAMES}" ]; then
        TF_VAR_ANTHOS_TARGET_CLUSTER_MEMBERSHIP_NAMES="\"$MEMBERSHIP\""
      else
        TF_VAR_ANTHOS_TARGET_CLUSTER_MEMBERSHIP_NAMES="\"$MEMBERSHIP\",${TF_VAR_ANTHOS_TARGET_CLUSTER_MEMBERSHIP_NAMES}"
      fi
    done

  fi
  if [ -n "${TF_VAR_ANTHOS_TARGET_CLUSTER_MEMBERSHIP_NAMES}" ]; then
    TF_VAR_ANTHOS_TARGET_CLUSTER_MEMBERSHIP_NAMES="[${TF_VAR_ANTHOS_TARGET_CLUSTER_MEMBERSHIP_NAMES}]"
  else
    TF_VAR_ANTHOS_TARGET_CLUSTER_MEMBERSHIP_NAMES="[]"
  fi

  if [ "${GENERATE_TFVARS_FILE}" = "true" ]; then
    check_argument "${GOOGLE_CLOUD_DEFAULT_PROJECT}" "${GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION}"
    check_argument "${GOOGLE_CLOUD_DEFAULT_REGION}" "${GOOGLE_CLOUD_DEFAULT_REGION_DESCRIPTION}"
    check_argument "${GOOGLE_CLOUD_DEFAULT_ZONE}" "${GOOGLE_CLOUD_DEFAULT_ZONE_DESCRIPTION}"
    check_argument "${GOOGLE_CLOUD_VIAI_STORAGE_BUCKET_LOCATION}" "${GOOGLE_CLOUD_VIAI_STORAGE_BUCKET_LOCATION_DESCRIPTION}"
    check_argument "${GOOGLE_CLOUD_DEFAULT_USER_EMAIL}" "${GOOGLE_CLOUD_DEFAULT_USER_EMAIL_DESCRIPTION}"

    echo "Generating ${TERRAFORM_TFVARS_PATH}..."
    if [ -f "${TERRAFORM_TFVARS_PATH}" ]; then
      echo "[ERROR]: The ${TERRAFORM_TFVARS_PATH} file already exists. Delete it before generating a new one. Terminating..."
      # Ignoring because those are defined in common.sh, and don't need quotes
      # shellcheck disable=SC2086
      exit ${ERR_ARGUMENT_EVAL_ERROR}
    else
      tee "${TERRAFORM_TFVARS_PATH}" <<EOF
google_default_region             = "${GOOGLE_CLOUD_DEFAULT_REGION}"
google_default_zone               = "${GOOGLE_CLOUD_DEFAULT_ZONE}"
google_viai_project_id            = "${GOOGLE_CLOUD_DEFAULT_PROJECT}"
viai_storage_buckets_location     = "${GOOGLE_CLOUD_VIAI_STORAGE_BUCKET_LOCATION}"
google_cloud_console_user_email   = "${GOOGLE_CLOUD_DEFAULT_USER_EMAIL}"
cloud_function_source_path        = "${VIAI_CAMERA_INTEGRATION_FILE_PATH}"
anthos_target_cluster_membership  = ${TF_VAR_ANTHOS_TARGET_CLUSTER_MEMBERSHIP_NAMES}
create_sandbox                    = "${SANDBOX}"
EOF
    fi
  fi

fi

# Stores service account key files.
mkdir -p "$(pwd)"/tmp

run_containerized_terraform "${GOOGLE_APPLICATION_CREDENTIALS_PATH}" "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}" version
run_containerized_terraform "${GOOGLE_APPLICATION_CREDENTIALS_PATH}" "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}" init -backend-config="bucket=tf-state-${DEFAULT_PROJECT}"
run_containerized_terraform "${GOOGLE_APPLICATION_CREDENTIALS_PATH}" "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}" validate
run_containerized_terraform "${GOOGLE_APPLICATION_CREDENTIALS_PATH}" "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}" "${TERRAFORM_SUBCOMMAND}"

if [ "${TERRAFORM_SUBCOMMAND}" = "destroy" ]; then
  # Destroy Cloud Resources
  RUNTIME_SCRIPT_FOLDER="$(mktemp -d)"

  cat <<EOF >"${RUNTIME_SCRIPT_FOLDER}/destroy.sh"
if gsutil list -p "${DEFAULT_PROJECT}" | grep "gs://tf-state-${DEFAULT_PROJECT}/" ; then
  echo "Terraform backend storage exists, deleting..."
  gsutil rm -r gs://tf-state-${DEFAULT_PROJECT}
else
  echo "Terraform backend does not exists, skip..."
fi
EOF
  gcloud_exec_scripts "${GOOGLE_APPLICATION_CREDENTIALS_PATH}" "${RUNTIME_SCRIPT_FOLDER}" "destroy.sh"
fi

echo "Clean up ${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}..."
rm -rf "$VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH"

trap 'echo "Cleaning up..."; rm -fr "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}"; rm -fr "${RUNTIME_SCRIPT_FOLDER}"' EXIT
