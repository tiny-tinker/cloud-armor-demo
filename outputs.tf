
output "cluster_name" {
  value       = google_container_cluster.primary.name
  description = "The name of the cluster"
}

output "sec_policy" {
  value       = google_compute_security_policy.sec-policy.name
  description = "The name of the security policy"
}
