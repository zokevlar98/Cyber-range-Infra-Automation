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
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all internal traffic" 
    #VXLAN traffic (UDP 4789) will be allowed by the "Allow all internal traffic" rule.
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

# EC2 Instance defaults
locals {
  instance_defaults = {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }
}

# Red Team Instance
resource "aws_instance" "red_team" {
  ami           = var.ubuntu_ami
  instance_type = var.instance_types["red_team"]
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
    Name = "${var.project_name}-red"
    Role = "red-team"
  })

  provisioner "local-exec" {
    when = create
    command = "ansible-playbook -i '${self.public_ip},' -u ubuntu --private-key ${var.key_name}.pem ${var.red_team_playbook}"
  }
  # provisioner "Local-exec" {
  #   command = <<EOF

  # }
}

# Blue Team Instance
resource "aws_instance" "blue_team" {
  ami           = var.ubuntu_ami
  instance_type = var.instance_types["blue_team"]
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

# Target Instance
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



resource "aws_lb" "net_lb" {
  name               = "${var.project_name}-net-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public.id]
  ip_address_type    = "ipv4"

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "net_tg" {
  name     = "${var.project_name}-net-tg"
  port     = 22
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    interval            = 30
    protocol            = "TCP"
    timeout             = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "net_lb_listener" {
  load_balancer_arn = aws_lb.net_lb.arn
  port              = 22
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.net_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "red_team" {
  target_group_arn = aws_lb_target_group.net_tg.arn
  target_id        = aws_instance.blue_team.id
  port             = 22
}

resource "aws_lb_target_group_attachment" "blue_team" {
  target_group_arn = aws_lb_target_group.net_tg.arn
  target_id        = aws_instance.blue_team.id
  port             = 22
}

resource "aws_lb_target_group_attachment" "target" {
  target_group_arn = aws_lb_target_group.net_tg.arn
  target_id        = aws_instance.target.id
  port             = 22
}

#traffic mirror target
resource "aws_ec2_traffic_mirror_target" "blue_team_target" {
  description          = "Mirror target for blue team analysis"
  network_interface_id = aws_instance.blue_team.primary_network_interface_id
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-mirror-target"
  })
}
#Mirror traffic filter
resource "aws_ec2_traffic_mirror_filter" "target_traffic" {
  description      = "Filter for target instance traffic"
  network_services = ["amazon-dns"]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-mirror-filter"
  })
}

# Rules for inbound traffic
resource "aws_ec2_traffic_mirror_filter_rule" "inbound" {
  description              = "Accept inbound traffic"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.target_traffic.id
  rule_number             = 1
  rule_action             = "accept"
  traffic_direction       = "ingress"
  destination_cidr_block  = "0.0.0.0/0"
  source_cidr_block      = "0.0.0.0/0"
}

# Rules for outbound traffic
resource "aws_ec2_traffic_mirror_filter_rule" "outbound" {
  description              = "Accept outbound traffic"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.target_traffic.id
  rule_number             = 2
  rule_action             = "accept"
  traffic_direction       = "egress"
  destination_cidr_block  = "0.0.0.0/0"
  source_cidr_block      = "0.0.0.0/0"
}

# Traffic mirror session
resource "aws_ec2_traffic_mirror_session" "target_session" {
  description              = "Traffic mirror session for target instance"
  network_interface_id     = aws_instance.target.primary_network_interface_id
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.target_traffic.id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.blue_team_target.id
  session_number          = 1

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-mirror-session"
  })
}

# Outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "instance_public_ip" {
  description = "Public IP of the instance"
  value = {
    red_team  = aws_instance.red_team.public_ip
    blue_team = aws_instance.blue_team.public_ip
    target    = aws_instance.target.public_ip
  }
}