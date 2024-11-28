provider "aws" {
  region = var.aws_region
}

# Data source for AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Resources
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-subnet"
    Type = "public"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-rt"
    Type = "public"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "instances" {
  name_prefix = "${var.project_name}-sg"
  description = "Security group for cyberrange instances"
  vpc_id      = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
    description = "SSH access"
  }

  #ingress {
  #  from_port   = 3000
  #  to_port     = 3000
  #  protocol    = "tcp"
  #  cidr_blocks = [var.allowed_ip]
  #  description = "Juice Shop access"
  #}

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all internal traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-sg"
  })
}

# EC2 Instance Module
locals {
  instance_defaults = {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }
}

# EC2 Instances
# resource "aws_instance" "kali" {
#   ami           = var.kali_ami
#   instance_type = var.instance_types["kali"]
#   key_name      = var.key_name

#   subnet_id                   = aws_subnet.public.id
#   vpc_security_group_ids      = [aws_security_group.instances.id]
#   associate_public_ip_address = true

#   root_block_device {
#     volume_size = local.instance_defaults.volume_size
#     volume_type = local.instance_defaults.volume_type
#     encrypted   = local.instance_defaults.encrypted
#   }
# }


#  metadata_options {
#    http_endpoint = "enabled"
#    http_tokens   = "required"
#  }

#  tags = merge(var.common_tags, {
#    Name = "${var.project_name}-kali"
#    Role = "red-team"
#  })
#}

resource "aws_instance" "blue_team" {
  ami           = var.ubuntu_ami
  instance_type = var.instance_types["blue"]
  key_name      = var.key_name

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.instances.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = local.instance_defaults.volume_size
    volume_type = local.instance_defaults.volume_type
    encrypted   = local.instance_defaults.encrypted
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-blue"
    Role = "blue-team"
  })
}

resource "aws_instance" "target" {
  ami           = var.ubuntu_ami
  instance_type = var.instance_types["target"]
  key_name      = var.key_name

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.instances.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = local.instance_defaults.volume_size
    volume_type = local.instance_defaults.volume_type
    encrypted   = local.instance_defaults.encrypted
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-target"
    Role = "target"
  })
}

# Outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "instance_ips" {
  description = "Public IPs of the instances"
  value = {
    #    kali   = aws_instance.kali.public_ip
    blue   = aws_instance.blue_team.public_ip
    target = aws_instance.target.public_ip
  }
}
