provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
}




resource "google_compute_instance" "bad-actor" {
  name         = "bad-actor"
  machine_type = "e2-medium"
  zone         = var.bad_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }


}




resource "google_container_cluster" "primary" {
  provider = google-beta
  name     = "my-gke-cluster"
  location = "us-central1"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 4

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    // Set to blank to have a range chosen with the default size
    cluster_ipv4_cidr_block = ""
  }


  addons_config {
    istio_config {
      disabled = false
      auth = "AUTH_MUTUAL_TLS"
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-standard-4"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    //service_account = google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}





resource "google_compute_security_policy" "sec-policy" {
  provider = google-beta
  depends_on = [
    google_compute_instance.bad-actor,
  ]

  name = var.sec-policy-name

  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = [ "${google_compute_instance.bad-actor.network_interface.0.access_config.0.nat_ip}/32"  ]
      }
    }
    description = "Deny access to IPs in ${google_compute_instance.bad-actor.network_interface.0.access_config.0.nat_ip}/32"
  }

  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default rule"
  }

  adaptive_protection_config {
    layer_7_ddos_defense_config {
        enable = true 
    }
  }
}



