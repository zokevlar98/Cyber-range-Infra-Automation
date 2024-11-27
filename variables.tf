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
  default     = "192.168.1.0/24"  # Replace with specific IP for better security

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

# Instance specific variables
# variable "kali_ami" {
#   description = "Kali Linux AMI ID - Update with latest AMI for production use"
#   type        = string
#   default     = "ami-07ee183bb1314209b"

#   validation {
#     condition     = length(var.kali_ami) >= 12 && substr(var.kali_ami, 0, 4) == "ami-"
#     error_message = "Must be a valid AMI ID, starting with 'ami-'."
#   }
# }


variable "ubuntu_ami" {
  description = "Ubuntu LTS AMI ID - Update with latest AMI for production use"
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
    kali    = "t2.micro"
    blue    = "t2.micro"
    target  = "t2.micro"
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
