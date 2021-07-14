
variable "project" {
  type        = string
  description = "Enter the name of the project to house the compute"
}


variable "region" {
  type        = string
  default     = "us-central1"
  description = "Enter the zone to deploy the compute instances"
}


variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "Enter the zone to deploy the compute instances"
}


variable "sec-policy-name" {
  type        = string
  default     = "my-security-policy"
  description = "The name of the network security policy"
}


