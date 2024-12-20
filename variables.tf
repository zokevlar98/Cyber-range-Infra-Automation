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
    red_team  = "t2.medium"
    blue_team = "t2.medium"
    target    = "t2.medium"
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

# # vunerable_lambda
variable "profile_pentester" {
  description = "The AWS profile to use."
  type        = string
  default     = "pentester"
}

variable "crid" {
  description = "CRID variable for unique naming."
  type        = string
  default     = "7"
}

# variable "cr_whitelist" {
#   description = "User's public IP address(es)."
#   # type        = list(string)
#   type = string
# }

variable "stack-name" {
  description = "Name of the stack."
  default     = "CayberRange_Stack"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario."
  default     = "vulnerable-lambda"
  type        = string
}

variable "lambda_name" {
  description = "Name of the lambda function."
  type        = string
  default     = "lambda_vulnerable"
}

variable "lambda_vpc_cidr" {
  description = "CIDR block for Lambda VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.lambda_vpc_cidr, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "lambda_subnet_cidr" {
  description = "CIDR block for Lambda subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.lambda_subnet_cidr, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}