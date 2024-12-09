# VPC for lambda components
resource "aws_vpc" "lambda_vpc" {
  cidr_block           = var.lambda_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.lambda_name}-vpc"
    Type = "vulnerable"
  }
}

# Create private subnet in vulnerable VPC
resource "aws_subnet" "lambda_private" {
  vpc_id                  = aws_vpc.lambda_vpc.id
  cidr_block              = var.lambda_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.lambda_name}-private-subnet"
    Type = "vulnerable"
  }
}
# Security group for Lambda instances
resource "aws_security_group" "lambda_instances" {
  name_prefix = "${var.lambda_name}-sg"
  description = "Security group for cyberrange instances"
  vpc_id      = aws_vpc.lambda_vpc.id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS Access"
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
    Name = "${var.lambda_name}-sg"
  })
}
# VPC Endpoint for Lambda
resource "aws_vpc_endpoint" "lambda" {
  vpc_id              = aws_vpc.lambda_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.lambda"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.lambda_private.id]
  security_group_ids  = [aws_security_group.lambda_endpoint.id]
  private_dns_enabled = true
  timeouts {
    create = "10m"
    delete = "10m"
  }
  depends_on = [ 
    aws_internet_gateway.lambda,
    aws_route.lambda_internet,
    aws_security_group.lambda_endpoint
   ]
}

# Security group for Lambda VPC endpoint
resource "aws_security_group" "lambda_endpoint" {
  name_prefix = "${var.lambda_name}-lambda-endpoint-sg"
  vpc_id      = aws_vpc.lambda_vpc.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_instances.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.lambda_name}-lambda-endpoint-sg"
  }
}

# VPC Peering between main and vulnerable VPCs
resource "aws_vpc_peering_connection" "main_to_lambda" {
  peer_vpc_id = aws_vpc.lambda_vpc.id
  vpc_id      = aws_vpc.main.id
  auto_accept = true

  tags = {
    Name = "${var.project_name}-vpc-peering-lambda"
  }
}

# Route table for lambda VPC
resource "aws_route_table" "lambda" {
  vpc_id = aws_vpc.lambda_vpc.id

  route {
    cidr_block                = aws_vpc.main.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.main_to_lambda.id
  }

  tags = {
    Name = "${var.lambda_name}-rt"
  }
}

resource "aws_route_table_association" "lambda" {
  subnet_id      = aws_subnet.lambda_private.id
  route_table_id = aws_route_table.lambda.id
}

# Add route to main VPC route table
resource "aws_route" "main_to_lambda" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = aws_vpc.lambda_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main_to_lambda.id
}

# Add Internet Gateway for Lambda VPC
resource "aws_internet_gateway" "lambda" {
  vpc_id = aws_vpc.lambda_vpc.id

  tags = {
    Name = "${var.lambda_name}-igw"
  }
}

# Add route to Internet Gateway in Lambda route table
resource "aws_route" "lambda_internet" {
  route_table_id         = aws_route_table.lambda.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lambda.id
}

# Save credentials using local-exec
resource "null_resource" "save_credentials" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "AWS_ACCESS_KEY_ID=${aws_iam_access_key.pentester.id}" > aws_credentials.txt
      echo "AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.pentester.secret}" >> aws_credentials.txt
      echo "AWS_ACCOUNT_ID=${data.aws_caller_identity.current.account_id}" >> aws_credentials.txt
      echo "AWS_REGION=${var.aws_region}" >> aws_credentials.txt
      echo "ROLE_ARN=arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/cr-lambda-invoker-${var.crid}" >> aws_credentials.txt
      chmod 600 aws_credentials.txt
    EOT
  }

  depends_on = [
    aws_iam_access_key.pentester,
    aws_iam_user.pentester_user
  ]
}
