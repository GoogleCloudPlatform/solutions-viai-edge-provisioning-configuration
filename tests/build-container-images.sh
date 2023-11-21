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

# shellcheck disable=SC1091,SC1094
. ./scripts/common.sh

echo "Running lint checks"

_DOCKER_INTERACTIVE_TTY_OPTION=
if [ -t 0 ]; then
  _DOCKER_INTERACTIVE_TTY_OPTION="-it"
fi

YQ_CONTAINER_IMAGE_ID="$(grep <"docker/yq/Dockerfile" "yq" | awk -F ' ' '{print $2}')"
echo "Loaded yq container image ID: ${YQ_CONTAINER_IMAGE_ID}"

CONTAINER_BUILD_CI_JOB_PATH=".github/workflows/build-container-images.yml"

echo "Loading container image IDs from: ${CONTAINER_BUILD_CI_JOB_PATH}"
docker run --user "$(id -u)":"$(id -g)" --rm -v "$(pwd)":/workdir "${YQ_CONTAINER_IMAGE_ID}" '.jobs."build-container-images".strategy.matrix."container-image-context-directory"[]' "${CONTAINER_BUILD_CI_JOB_PATH}" | while read -r container_image_id; do
  echo "Building ${container_image_id} container image"
  docker build -t "${container_image_id}:latest" "docker/${container_image_id}"
done
