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




resource "random_string" "app_version" {
  length  = 4
  upper   = false
  special = false
}


resource "random_string" "bkt_name" {
  length  = 5
  upper   = false
  special = false
}





###### App Engine Stuff

resource "google_service_account" "appe_svc_acct" {
  account_id   = "my-app-eng-usr"
  display_name = "Service Account for App Engine"
}

resource "google_project_iam_member" "gae_api" {
  project = google_service_account.appe_svc_acct.project
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${google_service_account.appe_svc_acct.email}"
}

resource "google_project_iam_member" "storage_viewer" {
  project = google_service_account.appe_svc_acct.project
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.appe_svc_acct.email}"
}


resource "google_project_iam_member" "builder" {
  project = google_service_account.appe_svc_acct.project
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.appe_svc_acct.email}"
}





resource "google_storage_bucket" "source_bkt" {
  name                        = random_string.bkt_name.id
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "source_zip" {
  name   = "hello_world.zip"
  source = "./app/hello_world/hello_world.zip"
  bucket = google_storage_bucket.source_bkt.name

  depends_on = [
    google_storage_bucket.source_bkt
  ]
}



resource "google_app_engine_application" "app" {
  project     = var.project
  location_id = "us-central"
}



resource "google_app_engine_standard_app_version" "default" {
  version_id = random_string.app_version.id
  project    = var.project
  service    = "default"
  runtime    = "python39"

  entrypoint {
    # shell = "gunicorn main:app"
    # shell = "entrypoint: python3 main.py"
    shell = ""
  }
  deployment {
    zip {
      # source_url = google_storage_bucket_object.source_zip.media_link
      source_url = "https://storage.googleapis.com/${google_storage_bucket.source_bkt.name}/${google_storage_bucket_object.source_zip.name}"
    }
  }

  delete_service_on_destroy = true

  depends_on = [
    google_storage_bucket_object.source_zip,
    google_project_iam_member.builder
  ]

  service_account = google_service_account.appe_svc_acct.email

}



###### Load Balancer in front of AppEngine

module "lb-http" {
  // https://github.com/terraform-google-modules/terraform-google-lb-http/tree/v6.3.0/modules/serverless_negs
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "~> 6.3"
  name    = "my-sweet-lb"
  project = var.project

  ssl = false
  # managed_ssl_certificate_domains = [var.domain]
  # https_redirect                  = var.ssl
  labels = { "example-label" = "app-engine-example" }

  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.appengine_neg.id
        }
      ]
      enable_cdn              = false
      security_policy         = google_compute_security_policy.sec-policy.self_link
      custom_request_headers  = null
      custom_response_headers = null

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
      log_config = {
        enable      = true
        sample_rate = 1.0
      }
    }
  }
}


resource "google_compute_region_network_endpoint_group" "appengine_neg" {
  name                  = "appengine-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  app_engine {
    service = google_app_engine_standard_app_version.default.service
    version = google_app_engine_standard_app_version.default.version_id
  }
}

###### Cloud Armor Stuff 


resource "google_compute_security_policy" "sec-policy" {
  provider = google-beta
  depends_on = [
    google_compute_instance.bad-actor
  ]

  name = var.sec-policy-name

  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {

        src_ip_ranges = ["${google_compute_instance.bad-actor.network_interface.0.access_config.0.nat_ip}/32"]
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

  advanced_options_config {
    log_level = "VERBOSE"
  }

}




###### Bad Actor VM


resource "google_compute_instance" "bad-actor" {
  name         = "bad-actor"
  machine_type = "e2-medium"
  zone         = var.bad_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = var.the_network
    # No `access_config` means we won't give it an external IP
    access_config {} 
  }


}





###### Network Junk

resource "google_compute_router" "router" {
  name    = "my-router"
  region  = var.region
  network = var.the_network

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "my-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}



resource "google_compute_firewall" "ssh-rule" {
  name    = "demo-ssh"
  network = var.the_network
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = [google_compute_instance.bad-actor.name]
  # source_ranges = ["0.0.0.0/0"]
  source_ranges = ["35.235.240.0/20"]
}
