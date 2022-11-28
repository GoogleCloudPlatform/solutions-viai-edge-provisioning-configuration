resource "google_compute_address" "edge-server-anthos-static-internal-ip" {
  address_type = "INTERNAL"
  subnetwork   = google_compute_network.anthos-bare-metal.name
  name     = "edge-server-anthos-internal-ip"
  project = var.google_viai_project_id
  region  = var.google_default_region
}

resource "google_compute_address" "edge-server-anthos-static-external-ip" {
  address_type = "EXTERNAL"
  name     = "edge-server-anthos-external-ip"
  project = var.google_viai_project_id
  region  = var.google_default_region
}

resource "google_compute_instance" "edge-server-anthos-vm" {
  #ts:skip=AC_GCP_0041 https://github.com/tenable/terrascan/issues/1084
  name     = "gce-server-anthos"
  project = var.google_viai_project_id
  machine_type = "n1-standard-4"
  zone         = var.google_default_zone

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20221018"
      size = 500
    }
  }
  tags = ["edge-server"]
  guest_accelerator {
    type = "nvidia-tesla-t4"
    count = 1
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
  }

  network_interface {
    network = google_compute_network.anthos-bare-metal.name
    network_ip = google_compute_address.edge-server-anthos-static-internal-ip.address
    access_config {
      nat_ip =  google_compute_address.edge-server-anthos-static-external-ip.address
    }
  }

  service_account {
    email  = "viai-abm-service@${var.google_viai_project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<EOL
    # Install required packages

    ${file("${path.module}/../../scripts/machine-install-prerequisites.sh")}

    # Configures vxlan on the host machine.

    ${file("${path.module}/../../edge-server/anthos/node-setup-common.sh.tmpl")}

    # Default Control Plane VIP
    CONTROL_PLANE_VIP=192.168.200.170

    setup_vlan_control_plane

  EOL

  depends_on = [
      google_compute_address.edge-server-anthos-static-internal-ip
  ]
}
