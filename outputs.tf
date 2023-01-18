
output "sec_policy" {
  value       = google_compute_security_policy.sec-policy.name
  description = "The name of the security policy"
}

output "bad_actor_vm" {
  value       = google_compute_instance.bad-actor.name
  description = "The name of the bad-actor vm"
}

output "bad_zone" {
  value       = var.bad_zone
  description = "The zone the bad_actor_vm resides in."
}

output "app_url" {
  value = "http://${module.lb-http.external_ip}"
  description = "The url to the app"
}