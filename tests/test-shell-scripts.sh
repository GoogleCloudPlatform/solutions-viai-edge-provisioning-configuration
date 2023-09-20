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

set -o errexit
set -o nounset

OUTPUT_FOLDER="$(mktemp -d)"
export OUTPUT_FOLDER

mkdir -p tmp/
mkdir -p "${OUTPUT_FOLDER}"/kuberbetes
mkdir -p "${OUTPUT_FOLDER}"/scripts
mkdir -p "${OUTPUT_FOLDER}"/edge-server

cp kubernetes/viai-camera-integration/viai-camera-integration-gcp.yaml.tmpl "${OUTPUT_FOLDER}/kuberbetes/viai-camera-integration-gcp.yaml"

echo '{"type": "service_account"}' >tmp/service-account-key.json

export DEFAULT_PROJECT=dummy
export DEFAULT_REGION=dummy
export GOOGLE_CLOUD_DEFAULT_USER_EMAIL=kalschi@google.com
export K8S_RUNTIME=anthos
export MEMBERSHIP="${K8S_RUNTIME}-server-dummy"

echo "Generating Edge Server assets with the following values for options..."
echo "OUTPUT_FOLDER=${OUTPUT_FOLDER}"
echo "DEFAULT_PROJECT=${DEFAULT_PROJECT}"
echo "DEFAULT_REGION=${DEFAULT_REGION}"
echo "GOOGLE_CLOUD_DEFAULT_USER_EMAIL=${GOOGLE_CLOUD_DEFAULT_USER_EMAIL}"
echo "K8S_RUNTIME=${K8S_RUNTIME}"
echo "MEMBERSHIP=${MEMBERSHIP}"

scripts/1-generate-edge-server-assets.sh \
  -G tmp/service-account-key.json \
  -A tmp/service-account-key.json \
  -S tmp/service-account-key.json \
  -C tmp/service-account-key.json \
  -p "${DEFAULT_PROJECT}" \
  -k tmp/service-account-key.json \
  -r "${DEFAULT_REGION}" \
  -m "${MEMBERSHIP}" \
  -o "${OUTPUT_FOLDER}" \
  -i "${K8S_RUNTIME}" \
  -u "${GOOGLE_CLOUD_DEFAULT_USER_EMAIL}"

echo "VIAI Application assets generate completed."

export CONTAIMER_IMAGE_URL="gcr.io/my-project/my-image:tag"
./scripts/0-generate-viai-application-assets.sh \
  -m "${MEMBERSHIP}" \
  -p "${DEFAULT_PROJECT}" \
  -m "${MEMBERSHIP}" \
  -i "${K8S_RUNTIME}" \
  -r "1-2" \
  -t "${CONTAIMER_IMAGE_URL}" \
  -x
echo "Multiple Camera VIAI Application assets generate completed."

export MEDIA_TYPE="USB"
export K8S_RUNTIME="anthos"

cp tmp/service-account-key.json "${OUTPUT_FOLDER}/"

echo "Generating Media ISO file with the following values for options..."
echo "MEDIA_TYPE=${MEDIA_TYPE}"
echo "K8S_RUNTIME=${K8S_RUNTIME}"

scripts/2-generate-media-file.sh \
  --edge-config-directory-path "${OUTPUT_FOLDER}" \
  --media-type "${MEDIA_TYPE}" \
  --k8s-runtime "${K8S_RUNTIME}"

echo ".ISO file generate completed."

echo "Downlaod OS Image file..."
scripts/download-os-images.sh

echo "OS Image file download completed"
# shellcheck disable=SC1094
. scripts/common.sh
run_containerized_terraform version
