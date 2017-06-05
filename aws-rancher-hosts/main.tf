# Rancher server details
variable "server_hostname" {
  description = "Hostname of the Rancher server."
}

# Target server environment
variable "environment_id" {
  description = "Target environment id for host registration."
}

variable "environment_access_key" {
  description = "API access key for target environment"
}

variable "environment_secret_key" {
  description = "API secret key for target environment"
}

# Cluster setup
variable "cluster_name" {
  description = "The name of the cluster. Best not to include non-alphanumeric characters. Will be used to name resources and tag instances."
}

variable "cluster_autoscaling_group_name" {
  description = "Name of the target autoscaling group."
}

variable "cluster_instance_security_group_id" {
  description = "ID of the security group used for host instances. Will be modified to include rancher specific rules."
}

variable "cluster_instance_labels" {
  description = "Additional labels to attach to host instances. Should be in the format: key=value&key2=value2"
  default     = ""
}
