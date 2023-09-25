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

# shellcheck disable=SC1094
. ./scripts/common.sh

ANTHOS_VERSION_COMMON=$ANTHOS_VERSION

OUTPUT_FOLDER="$(mktemp -d)"
DEFAULT_PROJECT=dummy
DEFAULT_REGION=dummy
GOOGLE_CLOUD_DEFAULT_USER_EMAIL=kalschi@google.com
K8S_RUNTIME=anthos
MEMBERSHIP="${K8S_RUNTIME}-server-dummy"

export OUTPUT_FOLDER
export DEFAULT_PROJECT
export DEFAULT_REGION
export GOOGLE_CLOUD_DEFAULT_USER_EMAIL
export K8S_RUNTIME
export MEMBERSHIP

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

# # shellcheck disable=SC2046
GEN_VERSION=$(awk -F= '/ANTHOS_VERSION=/{gsub(/["'\'']/, "", $2); print $2}' "$OUTPUT_FOLDER/edge-server/node-setup.sh")

if [ "${GEN_VERSION}" = "${ANTHOS_VERSION_COMMON}" ]; then
  echo "Anthos Version: ($GEN_VERSION) == ${ANTHOS_VERSION_COMMON}"
  exit $EXIT_OK
else
  echo "Anthos Version: ($GEN_VERSION) != ${ANTHOS_VERSION_COMMON}"
  exit $EXIT_GENERIC_ERR
fi
