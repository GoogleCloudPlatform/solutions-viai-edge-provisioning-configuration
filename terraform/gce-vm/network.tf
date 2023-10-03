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

resource "google_compute_network" "anthos-bare-metal" {
  name                    = "anthos-bm-vpc"
  auto_create_subnetworks = true
  project                 = var.google_viai_project_id
}

resource "google_compute_router" "router" {
  project = var.google_viai_project_id
  name    = "${google_compute_network.anthos-bare-metal.name}-router"
  region  = var.google_default_region
  network = google_compute_network.anthos-bare-metal.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  project                            = var.google_viai_project_id
  name                               = "${google_compute_network.anthos-bare-metal.name}-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

}

resource "google_compute_firewall" "default-allows-internal" {
  name    = "allow-${google_compute_network.anthos-bare-metal.name}-internal"
  network = google_compute_network.anthos-bare-metal.name
  project = var.google_viai_project_id
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.128.0.0/9"]
  depends_on = [
    google_compute_network.anthos-bare-metal
  ]
}

resource "google_compute_firewall" "default-allows-icmp" {
  name    = "allows-${google_compute_network.anthos-bare-metal.name}-icmp"
  network = google_compute_network.anthos-bare-metal.name
  project = var.google_viai_project_id
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
  depends_on = [
    google_compute_network.anthos-bare-metal
  ]
}

resource "google_compute_firewall" "default-allows-ssh" {
  name    = "allows-${google_compute_network.anthos-bare-metal.name}-ssh"
  network = google_compute_network.anthos-bare-metal.name

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
  source_ranges = ["0.0.0.0/0"]
  depends_on = [
    google_compute_network.anthos-bare-metal
  ]
}

resource "google_compute_firewall" "allow-healthcheck" {
  name    = "allows-${google_compute_network.anthos-bare-metal.name}-healthcheck"
  network = google_compute_network.anthos-bare-metal.name
  project = var.google_viai_project_id
  allow {
    protocol = "tcp"
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  depends_on = [
    google_compute_network.anthos-bare-metal
  ]
}
