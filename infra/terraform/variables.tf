variable "aws_region" {
  description = "AWS region where the k3s node will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource tagging and naming"
  type        = string
  default     = "k3s-nginx-assignment"
}

variable "environment" {
  description = "Environment name used for resource tagging"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "K3s node EC2 instance type"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = length(var.instance_type) > 0
    error_message = "instance_type must not be empty."
  }
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 30

  validation {
    condition     = var.root_volume_size >= 20
    error_message = "root_volume_size must be at least 20 GiB for a usable k3s node."
  }
}

variable "k3s_install_channel" {
  description = "k3s release channel used by the boot-time Ansible installer"
  type        = string
  default     = "stable"

  validation {
    condition     = contains(["stable", "latest", "testing"], var.k3s_install_channel)
    error_message = "k3s_install_channel must be one of: stable, latest, testing."
  }
}

variable "key_pair_name" {
  description = "Name of the AWS EC2 key pair for SSH access to the k3s node"
  type        = string
  default     = "k3s-node-key"

  validation {
    condition     = length(var.key_pair_name) > 0
    error_message = "key_pair_name must not be empty."
  }
}

variable "ssh_public_key" {
  description = "Public SSH key to register as an AWS EC2 key pair. Set this in Terraform Cloud."
  type        = string

  validation {
    condition     = startswith(var.ssh_public_key, "ssh-rsa ") || startswith(var.ssh_public_key, "ssh-ed25519 ") || startswith(var.ssh_public_key, "ecdsa-sha2-")
    error_message = "ssh_public_key must be a valid OpenSSH public key."
  }
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH to the k3s node"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "ssh_allowed_cidr must be a valid CIDR block, for example 203.0.113.10/32."
  }
}

variable "nodeport_allowed_cidr" {
  description = "CIDR block allowed to access Kubernetes NodePort services"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.nodeport_allowed_cidr, 0))
    error_message = "nodeport_allowed_cidr must be a valid CIDR block, for example 203.0.113.10/32."
  }
}
