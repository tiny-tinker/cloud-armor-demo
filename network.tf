# resource "google_compute_network" "lb-network" {
#   name = "lb-network"
# }



# # resource "google_compute_subnetwork" "us-subnet" {
# #   name          = "test-subnetwork"
# #   ip_cidr_range = "10.2.0.0/16"
# #   region        = "us-central1"
# #   network       = google_compute_network.lb-network.id
# #   secondary_ip_range {
# #     range_name    = "tf-test-secondary-range-update1"
# #     ip_cidr_range = "192.168.10.0/24"
# #   }
# # }


# resource "google_compute_firewall" "default-allow-http" {
#   name    = "default-allow-http"
#   network = google_compute_network.lb-network.name

#   allow {
#     protocol = "tcp"
#     ports    = ["80"]
#   }

#   target_tags = ["http-server"]

#   source_ranges = ["0.0.0.0/0"]
# }







# resource "google_compute_firewall" "default-allow-health-check" {
#   name    = "default-allow-health-check"
#   network = google_compute_network.lb-network.name

#   allow {
#     protocol = "tcp"
#   }

#   target_tags = ["http-server"]

#   source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
# }






# # gcloud compute networks subnets create us-subnet \
# #   --network=lb-network \
# #   --range=10.1.10.0/24 \
# #   --region=us-central1


# #   gcloud compute networks subnets create eu-subnet \
# #   --network=lb-network \
# #   --range=10.1.11.0/24 \
# #   --region=europe-west1
