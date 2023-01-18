
variable "project" {
  type        = string
  description = "Enter the name of the project to house the compute"
}


variable "the_network" {
  type        = string
  default     = "default"
  description = "The network to use. Should already be deployed."
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


variable "bad_zone" {
  type        = string
  default     = "europe-central2-a"
  description = "The region to put the bad-actor VM. the var.bad_net_cidr should be the cidr for the subnet in this zone"
}

variable "bad_net_cidr" {
  type        = string
  default     = "10.186.0.0/20"
  description = "cidr for the bad network in the var.bad_zone"
}
