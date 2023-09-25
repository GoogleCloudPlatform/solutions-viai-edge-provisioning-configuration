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

CONTAINER_REPO_HOST_DESCRIPTION="private container repo host name, ex, repo.private.com"
CONTAINER_REPO_USERNAME_DESCRIPTION="private container repo user name"
CONTAINER_REPO_PASSWORD_DESCRIPTION="passowrd of the private container repo user"
CONTAINER_REPO_REPOSITORY_NAME_DESCRIPION="name of private repo registry"
DEPLOYMENT_TEMP_FOLDER_DESCRIPTION="output folder path"
GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION="name of the default Google Cloud Project to use"
REPO_TYPE_DESCRIPTION="Container Registry type, can be [GCR] or [Private]"
VIAI_CAMERA_SRC_FOLDER_DESCRITPTION="VIAI Edge Camera application source folder path"
VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL_DESCRIPTION="the url of VIAI Camera application source repository"
VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH_DESCRIPTION="the branch name of VIAI Camera application source"
VIAI_CAMERA_APP_IMAGE_TAG_DESCRPITION="Tag of the cotnainer image."

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script builds VIAI application with Cloud Built."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -H $(is_linux && echo "| --container-repo-host"): ${CONTAINER_REPO_HOST_DESCRIPTION}"
  echo "  -U $(is_linux && echo "| --container-repo-user"): ${CONTAINER_REPO_USERNAME_DESCRIPTION}"
  echo "  -W $(is_linux && echo "| --container-repo-password"): ${CONTAINER_REPO_PASSWORD_DESCRIPTION}"
  echo "  -N $(is_linux && echo "| --container-repo-reg-name"): ${CONTAINER_REPO_REPOSITORY_NAME_DESCRIPION}"
  echo "  -p $(is_linux && echo "| --default-project"): ${GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION}"
  echo "  -l $(is_linux && echo "| --git-repo-url"): ${VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL_DESCRIPTION}"
  echo "  -b $(is_linux && echo "| --git-repo-branch"): ${VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH_DESCRIPTION}"
  echo "  -T $(is_linux && echo "| --image-tag"): ${VIAI_CAMERA_APP_IMAGE_TAG_DESCRPITION}"
  echo "  -a $(is_linux && echo "| --input-path"): ${VIAI_CAMERA_SRC_FOLDER_DESCRITPTION}"
  echo "  -o $(is_linux && echo "| --output-path"): ${DEPLOYMENT_TEMP_FOLDER_DESCRIPTION}"
  echo "  -Y $(is_linux && echo "| --repo-type"): ${REPO_TYPE_DESCRIPTION}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,container-repo-host:,container-repo-user:,container-repo-password:,container-repo-reg-name:,default-project:,git-repo-url:,git-repo-branch:,input-path:,image-tag:,output-path:,repo-type:"
SHORT_OPTIONS="hH:N:T:U:W:Y:a:b:l:o:p:"

CONTAINER_REPO_HOST=
CONTAINER_REPO_USERNAME=
CONTAINER_REPO_PASSWORD=
CONTAINER_REPO_REPOSITORY_NAME=
CONTAINER_REPO_TYPE=
DEPLOYMENT_TEMP_FOLDER=
GOOGLE_CLOUD_PROJECT=
VIAI_CAMERA_APP_IMAGE_TAG=
VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH=
VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL=sso://cloudsolutionsarchitects/viai-edge-camera-integration
VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH=dev

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
  -N | --container-repo-reg-name)
    CONTAINER_REPO_REPOSITORY_NAME="${2}"
    shift 2
    ;;
  -H | --container-repo-host)
    CONTAINER_REPO_HOST="${2}"
    shift 2
    ;;
  -U | --container-repo-user)
    CONTAINER_REPO_USERNAME="${2}"
    shift 2
    ;;
  -W | --container-repo-password)
    CONTAINER_REPO_PASSWORD="${2}"
    shift 2
    ;;
  -p | --default-project)
    GOOGLE_CLOUD_PROJECT="${2}"
    shift 2
    ;;
  -l | --git-repo-url)
    VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL="${2}"
    shift 2
    ;;
  -b | --git-repo-branch)
    VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH="${2}"
    shift 2
    ;;
  -T | --image-tag)
    VIAI_CAMERA_APP_IMAGE_TAG="${2}"
    shift 2
    ;;
  -a | --input-path)
    VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH="${2}"
    shift 2
    ;;
  -o | --output-path)
    # shellcheck disable=SC2034
    DEPLOYMENT_TEMP_FOLDER="${2}"
    shift 2
    ;;
  -Y | --repo-type)
    CONTAINER_REPO_TYPE="${2}"
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

echo "Creating and Pushing VIAI Camera Application docker image..."

clone_viai_camera_app "$VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH" "$VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL" "$VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH"

echo "Updating cloudbuild.yaml for VIAI Camera Application..."
if ! check_optional_argument "${VIAI_CAMERA_APP_IMAGE_TAG}" "${VIAI_CAMERA_APP_IMAGE_TAG_DESCRPITION}" "Use latest as tag name."; then
  VIAI_CAMERA_APP_IMAGE_TAG=latest
fi

if [ "$CONTAINER_REPO_TYPE" = "${CONST_CONTAINER_REPO_TYPE_GCR}" ] || [ "$CONTAINER_REPO_TYPE" = "${CONST_CONTAINER_REPO_TYPE_ARTIFACTREGISTRY}" ]; then
  echo "Copying cloudbuild.yaml for ${CONTAINER_REPO_TYPE} to $VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH/viai-edge-camera-integration/cloudbuild.yaml"
  cp "$(pwd)"/kubernetes/viai-camera-integration/cloudbuild-gcr.yaml.tmpl "$VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH"/viai-edge-camera-integration/cloudbuild.yaml
 else
  echo "Copying cloudbuild.yaml for Private Repo to $VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH/viai-edge-camera-integration/cloudbuild.yaml"
  cp "$(pwd)"/kubernetes/viai-camera-integration/cloudbuild-private-repo.yaml.tmpl "$VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH"/viai-edge-camera-integration/cloudbuild.yaml
fi
# This is an environment variable and a template variable, use single quota to avoid replacment
# shellcheck disable=SC2016,SC2086
sed -i'' 's/${GOOGLE_CLOUD_PROJECT}/'"${GOOGLE_CLOUD_PROJECT}"'/g' "$VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH"/viai-edge-camera-integration/cloudbuild.yaml
# This is an environment variable and a template variable, use single quota to avoid replacment
# shellcheck disable=SC2016,SC2086
sed -i'' 's/${CONTAINER_REPO_HOST}/'"${CONTAINER_REPO_HOST}"'/g' "$VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH"/viai-edge-camera-integration/cloudbuild.yaml
# This is an environment variable and a template variable, use single quota to avoid replacment
# shellcheck disable=SC2016,SC2086
sed -i'' 's/${CONTAINER_REPO_USERNAME}/'"${CONTAINER_REPO_USERNAME}"'/g' "$VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH"/viai-edge-camera-integration/cloudbuild.yaml
# This is an environment variable and a template variable, use single quota to avoid replacment
# shellcheck disable=SC2016,SC2086
sed -i'' 's/${CONTAINER_REPO_PASSWORD}/'"${CONTAINER_REPO_PASSWORD}"'/g' "$VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH"/viai-edge-camera-integration/cloudbuild.yaml

escape_slash "${CONTAINER_REPO_REPOSITORY_NAME}"
# This is an environment variable and a template variable, use single quota to avoid replacment
# shellcheck disable=SC2016,SC2086
sed -i'' 's/${CONTAINER_REPO_REPOSITORY_NAME}/'"${ESCAPED_NAME}"'/g' "$VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH"/viai-edge-camera-integration/cloudbuild.yaml
unset ESCAPED_NAME

# This is an environment variable and a template variable, use single quota to avoid replacment
# shellcheck disable=SC2016,SC2086
sed -i'' 's/${TAG}/'"${VIAI_CAMERA_APP_IMAGE_TAG}"'/g' "$VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH"/viai-edge-camera-integration/cloudbuild.yaml
GOOGLE_APPLICATION_CREDENTIALS_PATH="/root/.config/gcloud/application_default_credentials.json"

gcloud_auth

echo "Workspace:${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}/viai-edge-camera-integration"
echo "submit build job to cloud build at ${DEFAULT_REGION}"

# By default, CloudBuild creates a new bucket ${PROJECT_ID}_cloudbuild in US region to store soruce codes.
# We pre-creaeted a bucket with the same name in desired region in Terraform, so here Cloud Build will use the bucket in desired region.
# This is to avoid to hit GCP resource locations restriction.
docker run -it --rm \
  -e GOOGLE_APPLICATION_CREDENTIALS="${GOOGLE_APPLICATION_CREDENTIALS_PATH}" \
  -e DEFAULT_REGION="${DEFAULT_REGION}" \
  -v "${VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH}/viai-edge-camera-integration":/workspace \
  -v /etc/localtime:/etc/localtime:ro \
  --volumes-from "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" \
  "${GCLOUD_CLI_CONTAINER_IMAGE_ID}" \
  gcloud builds submit /workspace --async --config=/workspace/cloudbuild.yaml --project "${GOOGLE_CLOUD_PROJECT}" --region "${DEFAULT_REGION}"

# Cleanup
echo "Deleting $VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH/viai-edge-camera-integration/"
rm -rf "$VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH"/viai-edge-camera-integration/
