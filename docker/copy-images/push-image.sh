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

dockerd -H "${DOCKER_HOST}" --tls=false &

while (! docker stats --no-stream); do
  # Docker takes a few seconds to initialize
  echo "Waiting for Docker to launch..."
  sleep 1
done

echo "Pulling ${SOURCE_IMAGE}..."
docker pull "${SOURCE_IMAGE}"

echo "Tagging ${SOURCE_IMAGE} to ${CONTAINER_REPO_HOST}/${CONTAINER_REPO_REPOSITORY_NAME}/${TARGET_IMAGE_NAME}..."
docker tag "${SOURCE_IMAGE}" "${CONTAINER_REPO_HOST}/${CONTAINER_REPO_REPOSITORY_NAME}/${TARGET_IMAGE_NAME}"

if [ "${REGISTRY_TYPE}" != "Private" ]; then
  gcloud auth configure-docker ${CONTAINER_REPO_HOST} --quiet
else
  docker login "${CONTAINER_REPO_HOST}" --username="${CONTAINER_REPO_USERNAME}" --password="${CONTAINER_REPO_PASSWORD}"
fi

echo "Pushing ${SOURCE_IMAGE} to ${CONTAINER_REPO_HOST}/${CONTAINER_REPO_REPOSITORY_NAME}/${TARGET_IMAGE_NAME}..."

docker push "${CONTAINER_REPO_HOST}/${CONTAINER_REPO_REPOSITORY_NAME}/${TARGET_IMAGE_NAME}"
