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

# Update and upgrade APT reop
export DEBIAN_FRONTEND=noninteractive
apt-get -y update
apt-get -y upgrade

echo "Installing prerequisites..."
if ! command -v "kubectl" >/dev/null 2>&1; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
else
    echo "kubectl already been installed. skip..."
fi

if ! command -v "gcloud" >/dev/null 2>&1; then
    echo "Installing gcloud..."
    apt-get install -y apt-transport-https ca-certificates gnupg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    apt-get update -y && apt-get install -y google-cloud-cli
    echo "gcloud installation completed"
else
    echo "gcloud already been installed. skip..."
fi

if ! command -v "nvidia-smi" >/dev/null 2>&1; then
    apt-get install -y openssh-server apt-transport-https ca-certificates curl gnupg-agent software-properties-common

    echo "Installing NVIDIA Drivers..."
    apt-get install -y nvidia-headless-470-server nvidia-prime nvidia-utils-470-server

    systemctl disable nvidia-suspend.service
    systemctl disable nvidia-hibernate.service
    systemctl disable nvidia-resume.service

    rm -f /lib/systemd/system-sleep/nvidia
else
    echo "NVIDIA Drivers already been installed. skip..."
fi

# Configures vxlan on the host machine.
# Default Control Plane VIP
CONTROL_PLANE_VIP=192.168.200.170

apt-get install -y network-manager

LOCAL_IP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
LOCAL_NIC=$(ip -br -4 a sh | grep "${LOCAL_IP}" | awk '{print $1}')
echo "** Local IP: ${LOCAL_IP}, NIC: ${LOCAL_NIC}"

VXLAN_ID=104
VXLAN_NAME=vxlan104

# Ubuntu sets almost all devices unmanaged by default, this causes vxlan fails to start
# So we add vxlan related devices to the configuration file and restart network manager
if [ ! -f "/etc/NetworkManager/conf.d/10-globally-managed-devices.conf" ]; then
    touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
else
    sed -i 's/unmanaged-devices=*/unmanaged-devices=except:type:ethernet,except:type:vlan,except:type:vxlan,*/g' "/etc/NetworkManager/conf.d/10-globally-managed-devices.conf"
fi

systemctl restart NetworkManager

nmcli connection add type vxlan id "${VXLAN_ID}" remote "${LOCAL_IP}" ipv4.addresses "${CONTROL_PLANE_VIP}"/24 ipv4.method manual ifname "${VXLAN_NAME}" connection.id "${VXLAN_NAME}" vxlan.parent "${LOCAL_NIC}"
nmcli conn up "${VXLAN_NAME}"
