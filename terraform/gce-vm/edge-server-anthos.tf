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

resource "google_compute_address" "edge-server-anthos-static-internal-ip" {
  address_type = "INTERNAL"
  subnetwork   = google_compute_network.anthos-bare-metal.name
  name         = "edge-server-anthos-internal-ip"
  project      = var.google_viai_project_id
  region       = var.google_default_region
}

resource "google_compute_address" "edge-server-anthos-static-external-ip" {
  address_type = "EXTERNAL"
  name         = "edge-server-anthos-external-ip"
  project      = var.google_viai_project_id
  region       = var.google_default_region
}

resource "google_compute_instance" "edge-server-anthos-vm" {
  #ts:skip=AC_GCP_0041 https://github.com/tenable/terrascan/issues/1084
  name         = "gce-server-anthos"
  project      = var.google_viai_project_id
  machine_type = "n1-standard-4"
  zone         = var.google_default_zone

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20221018"
      size  = 500
    }
  }
  tags = ["edge-server"]
  guest_accelerator {
    type  = "nvidia-tesla-t4"
    count = 1
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
  }

  network_interface {
    network    = google_compute_network.anthos-bare-metal.name
    network_ip = google_compute_address.edge-server-anthos-static-internal-ip.address
    access_config {
      nat_ip = google_compute_address.edge-server-anthos-static-external-ip.address
    }
  }

  service_account {
    email  = "viai-abm-service@${var.google_viai_project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<EOL
    # TODO: Need to verify that this startup script is generated with references. @junholee

    # Update and upgrade APT reop
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y update
    apt-get -y upgrade
      
    # Install required packages
    ${file("${path.module}/../../scripts/machine-install-prerequisites.sh")}

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
  EOL

  depends_on = [
    google_compute_address.edge-server-anthos-static-internal-ip
  ]
}
