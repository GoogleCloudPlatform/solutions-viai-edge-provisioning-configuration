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
# shellcheck disable=SC1091
. scripts/common.sh
# Doesn't follow symlinks, but it's likely expected for most users
SCRIPT_BASENAME="$(basename "${0}")"
usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script generates a report about the current environment."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME}"
  echo
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo
}
usage
echo "Checking if the necessary dependencies are available..."
check_exec_dependency "cat"
check_exec_dependency "date"
check_exec_dependency "dpkg"
check_exec_dependency "host"
check_exec_dependency "ip"
check_exec_dependency "lsb_release"
check_exec_dependency "mkdir"
check_exec_dependency "mktemp"
check_exec_dependency "nslookup"
check_exec_dependency "nvidia-detector"
check_exec_dependency "nvidia-smi"
check_exec_dependency "ping"
check_exec_dependency "prime-select"
check_exec_dependency "snap"
check_exec_dependency "tar"
check_exec_dependency "uname"
check_exec_dependency "ubuntu-drivers"
REPORT_DESTINATION_DIRECTORY_NAME="viai-report"
REPORT_DESTINATION_DIRECTORY_PATH="$(mktemp -d)"
REPORT_WORKING_DIRECTORY="${REPORT_DESTINATION_DIRECTORY_PATH}/${REPORT_DESTINATION_DIRECTORY_NAME}"
mkdir -p "${REPORT_WORKING_DIRECTORY}"
NETWORK_REPORT_DESTINATION_DIRECTORY_PATH="${REPORT_WORKING_DIRECTORY}/network"
mkdir -p "${NETWORK_REPORT_DESTINATION_DIRECTORY_PATH}"
echo "Gathering information about the network devices..."
ip address show >"${NETWORK_REPORT_DESTINATION_DIRECTORY_PATH}/ip-address.log"
echo "Gathering information about IP routes..."
ip route show >"${NETWORK_REPORT_DESTINATION_DIRECTORY_PATH}/ip-route.log"
echo "Gathering information about name resolution..."
cat /etc/resolv.conf >"${NETWORK_REPORT_DESTINATION_DIRECTORY_PATH}/resolv.conf.log"
echo "Checking network connectivity..."
ping -c 4 "8.8.8.8" >"${NETWORK_REPORT_DESTINATION_DIRECTORY_PATH}/ping-ip-address.log"
HOSTNAME_TO_RESOLVE="google.com"
ping -c 4 "${HOSTNAME_TO_RESOLVE}" >"${NETWORK_REPORT_DESTINATION_DIRECTORY_PATH}/ping-hostname.log"
host "${HOSTNAME_TO_RESOLVE}" >"${NETWORK_REPORT_DESTINATION_DIRECTORY_PATH}/host.log"
nslookup "${HOSTNAME_TO_RESOLVE}" >"${NETWORK_REPORT_DESTINATION_DIRECTORY_PATH}/nslookup.log"
STORAGE_REPORT_DESTINATION_DIRECTORY_PATH="${REPORT_WORKING_DIRECTORY}/storage"
mkdir -p "${STORAGE_REPORT_DESTINATION_DIRECTORY_PATH}"
echo "Gathering information about disk space..."
df -h >"${STORAGE_REPORT_DESTINATION_DIRECTORY_PATH}/df.log"
PACKAGES_REPORT_DESTINATION_DIRECTORY_PATH="${REPORT_WORKING_DIRECTORY}/packages"
mkdir -p "${PACKAGES_REPORT_DESTINATION_DIRECTORY_PATH}"
echo "Gathering information about installed packages..."
dpkg -l >"${PACKAGES_REPORT_DESTINATION_DIRECTORY_PATH}/dpkg-l.log"
snap list >"${PACKAGES_REPORT_DESTINATION_DIRECTORY_PATH}/snap-list.log"
OS_REPORT_DESTINATION_DIRECTORY_PATH="${REPORT_WORKING_DIRECTORY}/os"
mkdir -p "${OS_REPORT_DESTINATION_DIRECTORY_PATH}"
echo "Gathering information about the operating system..."
lsb_release -a >"${OS_REPORT_DESTINATION_DIRECTORY_PATH}/lsb_release.log"
uname -a >"${OS_REPORT_DESTINATION_DIRECTORY_PATH}/uname.log"
HARDWARE_REPORT_DESTINATION_DIRECTORY_PATH="${REPORT_WORKING_DIRECTORY}/hardware"
mkdir -p "${HARDWARE_REPORT_DESTINATION_DIRECTORY_PATH}"
echo "Gathering information about the hardware..."
cat /proc/cpuinfo >"${HARDWARE_REPORT_DESTINATION_DIRECTORY_PATH}/proc-cpuinfo.log"
echo "Gathering information about drivers..."
GPU_REPORT_DESTINATION_DIRECTORY_PATH="${REPORT_WORKING_DIRECTORY}/gpu"
mkdir -p "${GPU_REPORT_DESTINATION_DIRECTORY_PATH}"
ubuntu-drivers devices >"${GPU_REPORT_DESTINATION_DIRECTORY_PATH}/ubuntu-drivers-devices.log"
nvidia-detector >"${GPU_REPORT_DESTINATION_DIRECTORY_PATH}/nvidia-detector.log"
prime-select query >"${GPU_REPORT_DESTINATION_DIRECTORY_PATH}/prime-select-query.log"
nvidia-smi >"${GPU_REPORT_DESTINATION_DIRECTORY_PATH}/nvidia-smi.log"
NOW_TIMESTAMP="$(date +"%Y-%m-%d-%H-%M-%S")"
REPORT_DESTINATION_FILE_PATH="${REPORT_DESTINATION_DIRECTORY_PATH}/${REPORT_DESTINATION_DIRECTORY_NAME}-${NOW_TIMESTAMP}.tar.gz"
tar \
  --create \
  --directory="${REPORT_DESTINATION_DIRECTORY_PATH}" \
  --file "${REPORT_DESTINATION_FILE_PATH}" \
  --gzip \
  "${REPORT_DESTINATION_DIRECTORY_NAME}"
echo "Cleaning up..."
rm -rf "${REPORT_WORKING_DIRECTORY}"
echo "The report is available at ${REPORT_DESTINATION_FILE_PATH}"
