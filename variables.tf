variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name to be used for tagging"
  type        = string
  default     = "cyberrange"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ip" {
  description = "IP address allowed to connect to instances"
  type        = string
  default     = "0.0.0.0/0"  # Replace with our IP
}

variable "key_name" {
  description = "Name of SSH key pair"
  type        = string
  default     = "cyberrange-key"
}

# Instance specific variables
variable "kali_ami" {
  description = "Kali Linux AMI ID"
  type        = string
  default     = "ami-0b7061ad80874a692"  # Replace with latest Kali Linux AMI (we can make it dynamicly later)
}

variable "ubuntu_ami" {
  description = "Ubuntu LTS AMI ID"
  type        = string
  default     = "ami-0c65adc9a5c1b5d7c"  # Replace with latest Ubuntu 22.04 LTS AMI (we can make it dynamicly later)
}

variable "instance_types" {
  description = "Instance types for different purposes"
  type        = map(string)
  default = {
    kali    = "t2.micro"
    blue    = "t2.micro"
    target  = "t2.micro"
  }
}
