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

export OUTPUT_FOLDER="$(mktemp -d)"
export DEFAULT_PROJECT=dummy
export DEFAULT_REGION=dummy
export GOOGLE_CLOUD_DEFAULT_USER_EMAIL=kalschi@google.com
export K8S_RUNTIME=anthos
export MEMBERSHIP="${K8S_RUNTIME}-server-dummy"

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

ANTHOS_VERSION_GEN_SCRIPT=$ANTHOS_VERSION

echo "ANTHOS_VERSION_GEN_SCRIPT=${ANTHOS_VERSION_GEN_SCRIPT}"
echo "ANTHOS_VERSION_COMMON=${ANTHOS_VERSION_COMMON}"

if [ "$ANTHOS_VERSION_GEN_SCRIPT" == "$ANTHOS_VERSION_COMMON" ]; then
    echo "Versions are equal"
    exit $EXIT_OK
else
    echo "Versions are not equal"
    exit $EXIT_GENERIC_ERR
fi
