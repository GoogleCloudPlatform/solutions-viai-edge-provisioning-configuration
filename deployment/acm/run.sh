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

gcloud config set project "${PROJECT_ID}"

mkdir -p /src

cd /

git config --global credential.'https://source.developers.google.com'.helper gcloud.sh

gcloud source repos clone acm-repo --project="${PROJECT_ID}"

cp -r /kubernetes/* /acm-repo

cd /acm-repo || exit 1
git config --global user.email "${USER_EMAIL}"
git config --global user.name "${USER_ID}"

echo "checking out ${BRANCH}..."
git checkout "${BRANCH}"

echo "commit..."
git add .
git commit -m "update"

echo "pushing..."
git push
