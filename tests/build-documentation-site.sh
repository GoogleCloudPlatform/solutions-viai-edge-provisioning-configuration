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

echo "Building Jekyll"

docker build -t jekyll:4.3.2 -f docker/documentation-site-builder/Dockerfile .

echo "Rendering documentation site"
echo "Open your browser at http://127.0.0.1:4000/docs/ to review the documentation locally"

docker run -p 4000:4000 jekyll:4.3.2