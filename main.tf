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
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    # No `access_config` means we won't give it an external IP
  }


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
  source = "./app/hello_world.zip"
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

  entrypoint{
    shell = "entrypoint: gunicorn -b :$PORT main:app"
  }
  deployment {
    zip {
      source_url = google_storage_bucket_object.source_zip.media_link
    }
  }

  delete_service_on_destroy = true

  depends_on = [
     google_storage_bucket_object.source_zip,
     google_project_iam_member.builder
     ]
  
  service_account = google_service_account.appe_svc_acct.email

}




# resource "google_compute_security_policy" "sec-policy" {
#   provider = google-beta
#   depends_on = [
#     google_compute_instance.bad-actor,
#   ]

#   name = var.sec-policy-name

#   rule {
#     action   = "deny(403)"
#     priority = "1000"
#     match {
#       versioned_expr = "SRC_IPS_V1"
#       config {
#         src_ip_ranges = ["${google_compute_instance.bad-actor.network_interface.0.access_config.0.nat_ip}/32"]
#       }
#     }
#     description = "Deny access to IPs in ${google_compute_instance.bad-actor.network_interface.0.access_config.0.nat_ip}/32"
#   }

#   rule {
#     action   = "allow"
#     priority = "2147483647"
#     match {
#       versioned_expr = "SRC_IPS_V1"
#       config {
#         src_ip_ranges = ["*"]
#       }
#     }
#     description = "default rule"
#   }

#   adaptive_protection_config {
#     layer_7_ddos_defense_config {
#       enable = true
#     }
#   }
# }



