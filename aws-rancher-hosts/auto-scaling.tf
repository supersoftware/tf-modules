# User-data template
# Registers the instance with the rancher server environment
resource "template_file" "user_data" {
  template = "${file("${path.module}/files/userdata.template")}"

  vars {
    cluster_name            = "${var.cluster_name}"
    cluster_instance_labels = "${var.cluster_instance_labels}"
    environment_id          = "${var.environment_id}"
    environment_access_key  = "${var.environment_access_key}"
    environment_secret_key  = "${var.environment_secret_key}"
    server_hostname         = "${var.server_hostname}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "host_user_data" {
  value = "${template_file.user_data.rendered}"
}
