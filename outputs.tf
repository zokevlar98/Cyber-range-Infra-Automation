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

# New outputs for Lambda and VPC configuration
output "lambda_function_details" {
  description = "Details of the vulnerable Lambda function"
  value = {
    function_name = aws_lambda_function.policy_applier_lambda1.function_name
    function_arn  = aws_lambda_function.policy_applier_lambda1.arn
    vpc_config = {
      vpc_id             = aws_vpc.lambda_vpc.id
      subnet_id          = aws_subnet.lambda_private.id
      security_group_id  = aws_security_group.lambda_endpoint.id
    }
    vpc_endpoint = {
      endpoint_id = aws_vpc_endpoint.lambda.id
      dns_entry   = aws_vpc_endpoint.lambda.dns_entry
    }
  }
}

# output "vpc_peering_connection_id" {
#   description = "ID of VPC peering connection between main and vulnerable VPCs"
#   value       = aws_vpc_peering_connection.main_to_vulnerable.id
# }

output "lambda_invoke_url" {
  description = "URL to invoke the Lambda function (via VPC endpoint)"
  value       = "https://${aws_lambda_function.policy_applier_lambda1.function_name}.${var.aws_region}.amazonaws.com"
}

output "lambda_access_instructions" {
  description = "Instructions for accessing the vulnerable Lambda"
  value = <<EOF
Lambda Function Access Information:
- Function Name: ${aws_lambda_function.policy_applier_lambda1.function_name}
- Region: ${var.aws_region}
- VPC Endpoint DNS: ${aws_vpc_endpoint.lambda.dns_entry[0]["dns_name"]}

To invoke the Lambda function:
1. From Red Team instance (${aws_instance.red_team.public_ip}):
   aws lambda invoke --function-name ${aws_lambda_function.policy_applier_lambda1.function_name} \
   --payload '{"action": "test"}' response.json

2. Through VPC Endpoint:
   curl -X POST ${aws_vpc_endpoint.lambda.dns_entry[0]["dns_name"]} \
   -H "Content-Type: application/json" \
   -d '{"action": "test"}'
EOF
}


output "pentester_user_credentials" {
  description = "Credentials for the pentester user"
  value = {
    access_key = aws_iam_access_key.pentester.id
    secret_key = aws_iam_access_key.pentester.secret
    user_arn   = aws_iam_user.pentester_user.arn
    account_id = data.aws_caller_identity.current.account_id
  }
  sensitive = true
}
