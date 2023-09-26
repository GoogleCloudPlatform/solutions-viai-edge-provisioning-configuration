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

download_file_if_necessary "${OS_INSTALLER_IMAGE_URL}" "${OS_INSTALLER_IMAGE_PATH}"

# We assume there's a checksum file path to verify the downloaded image
OS_IMAGE_CHECKSUM_FILE_PATH="${WORKING_DIRECTORY}/$(basename "${OS_IMAGE_CHECKSUM_FILE_URL}")"
download_file_if_necessary "${OS_IMAGE_CHECKSUM_FILE_URL}" "${OS_IMAGE_CHECKSUM_FILE_PATH}"
echo "Verifying the integrity of ${OS_INSTALLER_IMAGE_PATH} downloaded files using ${OS_IMAGE_CHECKSUM_FILE_PATH}"
if is_linux; then
  sha256sum \
    --check \
    --ignore-missing \
    "${OS_IMAGE_CHECKSUM_FILE_PATH}"
elif is_macos; then
  shasum \
    -a "256" \
    -c \
    --ignore-missing \
    "${OS_IMAGE_CHECKSUM_FILE_PATH}"
fi

echo "OS image downloaded and verified: ${OS_INSTALLER_IMAGE_PATH}"
