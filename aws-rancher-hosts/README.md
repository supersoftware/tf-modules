This module is based on [greensheep/terraform-aws-rancher-hosts(https://github.com/greensheep/terraform-aws-rancher-hosts)] but is simplified. (e.g. No SQS to remove hosts)
Don't use this in production.

# Rancher host cluster Terraform module

This is a terraform module to help with creating a rancher host cluster.

### Features

- Flexible for use with different deployment scenarios.
- Automatically adds hosts launched by autoscaling to the Rancher server.
- Designed for use in VPC private subnets so can be used for private, backend services or proxy traffic from an ELB for public services.
- Can be used unlimited times in a terraform config. Allows creation of separate clusters for dev, staging, production, etc.
- This module **does not remove the hosts automatically on autoscale termination** like the original one.  Hence it does not create SQS or IAM roles.

### Requirements

Terraform 0.6.6 is required.

On it's own this doesn't do very much. It needs to be included in a Terraform config that creates the following resources:

- Security group
- Autoscaling launch configuration
- Autoscaling group

Because these resources may vary significantly for your deployment (eg, the type of app you're deploying, expected workload, etc), you need to create these yourself and pass in the necessary variables.

### Usage

Include the following in your existing terraform config:

    module "staging_cluster" {
      # Import the module from Github
      # It's probably better to fork or clone this repo if you intend to use in production
      # so any future changes dont mess up your existing infrastructure.
      source = "github.com/supersoftware/tf-modules//aws-rancher-hosts"
    
      # Add Rancher server details
      server_hostname = "try.rancher.com"
    
      # Rancher environment
      # In your Rancher server, create an environment and an API keypair. You can have
      # multiple host clusters per environment if necessary. Instances will be labelled
      # with the cluster name so you can differentiate between multiple clusters.
      environment_id = "${var.rancher_environment_id}"
    
      environment_access_key = "${var.rancher_environment_access_key}"
      environment_secret_key = "${var.rancher_environment_secret_key}"
    
      # Name your cluster and provide the autoscaling group name and security group id.
      cluster_name = "${var.cluster_name}"
    
      cluster_autoscaling_group_name = "${aws_autoscaling_group.cluster_autoscale_group.id}"
    
      cluster_instance_security_group_id = "${aws_security_group.cluster_instance_sg.id}"
    }

### Examples of required resources

##### Security group

    # Cluster instance security group
    resource "aws_security_group" "cluster_instance_sg" {
      name        = "Rancher-Cluster-Instances"
      description = "Rules for connected Rancher host machines. These are the hosts that run containers placed on the cluster."
      vpc_id      = "${var.target_vpc_id}"
    
      lifecycle {
        create_before_destroy = true
      }
    }


##### Autoscaling

    # Autoscaling launch configuration
    resource "aws_launch_configuration" "cluster_launch_conf" {
      name = "Launch-Config"
    
      # Amazon linux, ap-northeast-1
      image_id = "${var.rancheros_ami}"
    
      # No public ip when instances are placed in private subnets.
      associate_public_ip_address = false
    
      # Security groups
      security_groups = [
        "${aws_security_group.cluster_instance_sg.id}",
      ]
    
      # Key
      key_name = "${var.ec2_key_name}"
    
      # Add rendered userdata template
      user_data = "${module.staging_cluster.host_user_data}"
    
      # Misc
      instance_type     = "t2.micro"
      enable_monitoring = true
    
      lifecycle {
        create_before_destroy = true
      }
    }
    
    # Autoscaling group
    resource "aws_autoscaling_group" "cluster_autoscale_group" {
      name                      = "Cluster-ASG"
      launch_configuration      = "${aws_launch_configuration.cluster_launch_conf.name}"
      min_size                  = "${var.asg_min_size}"
      max_size                  = "${var.asg_max_size}"
      desired_capacity          = "${var.asg_desired_capacity}"
      health_check_grace_period = 180
      health_check_type         = "EC2"
      force_delete              = false
      termination_policies      = ["OldestInstance"]
    
      # Target subnets
      vpc_zone_identifier = ["${var.vpc_private_subnet_ids}"]
    
      tag {
        key                 = "Name"
        value               = "Test-Rancher-Cluster-Instance"
        propagate_at_launch = true
      }
    
      lifecycle {
        create_before_destroy = true
      }
    }
