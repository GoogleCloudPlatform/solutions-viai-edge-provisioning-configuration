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

LINT_CI_JOB_PATH=".github/workflows/lint.yml"
DEFAULT_LINTER_CONTAINER_IMAGE_VERSION="$(grep <"${LINT_CI_JOB_PATH}" "super-linter/super-linter" | awk -F '@' '{print $2}')"

LINTER_CONTAINER_IMAGE="ghcr.io/super-linter/super-linter:${LINTER_CONTAINER_IMAGE_VERSION:-${DEFAULT_LINTER_CONTAINER_IMAGE_VERSION}}"

echo "Running linter container image: ${LINTER_CONTAINER_IMAGE}"

# shellcheck disable=SC2086
docker run \
  ${_DOCKER_INTERACTIVE_TTY_OPTION} \
  --env ACTIONS_RUNNER_DEBUG="${ACTIONS_RUNNER_DEBUG:-"false"}" \
  --env MULTI_STATUS="false" \
  --env RUN_LOCAL="true" \
  --env-file "config/lint/super-linter.env" \
  --name "super-linter" \
  --rm \
  --volume "$(pwd)":/tmp/lint \
  --volume /etc/localtime:/etc/localtime:ro \
  --workdir /tmp/lint \
  "${LINTER_CONTAINER_IMAGE}" \
  "$@"

unset _DOCKER_INTERACTIVE_TTY_OPTION
