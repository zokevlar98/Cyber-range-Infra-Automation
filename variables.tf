variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Project name to be used for tagging"
  type        = string
  default     = "cyberrange"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "192.168.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "192.168.1.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "allowed_ip" {
  description = "IP address/range allowed to connect to instances (CIDR notation)"
  type        = string
  default     = "192.168.1.0/24"

  validation {
    condition     = can(cidrhost(var.allowed_ip, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "key_name" {
  description = "Name of SSH key pair used for instance access"
  type        = string
  default     = "cyberrange-key"

  validation {
    condition     = length(var.key_name) > 0
    error_message = "Key name cannot be empty."
  }
}

variable "ubuntu_ami" {
  description = "Ubuntu LTS AMI ID"
  type        = string
  default     = "ami-0e1e4dabd4687bd08"

  validation {
    condition     = length(var.ubuntu_ami) >= 12 && substr(var.ubuntu_ami, 0, 4) == "ami-"
    error_message = "Must be a valid AMI ID, starting with 'ami-'."
  }
}

variable "instance_types" {
  description = "Instance types for different purposes"
  type        = map(string)
  default = {
    red_team  = "t2.micro"
    blue_team = "t2.micro"
    target    = "t2.micro"
  }

  validation {
    condition = alltrue([
      for type in values(var.instance_types) :
      can(regex("^[a-z][1-9][.][a-z]+$", type))
    ])
    error_message = "Instance types must be valid AWS instance type formats."
  }
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Project   = "cyberrange"
    ManagedBy = "terraform"
  }
}

variable "red_team_playbook" {
  description = "Path to the Red Team playbook"
  type        = string
  default     = "/mnt/c/Users/zokevlar/Desktop/Cyber-range-Infra-Automation/ansible/red_team_playbook.yml"

  validation {
    condition     = can(file(var.red_team_playbook))
    error_message = "File not found."
  }

}