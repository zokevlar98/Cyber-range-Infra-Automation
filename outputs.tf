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

# output "pentester_user_credentials" {
#   value = {
#     access_key = aws_iam_access_key.pentester.id
#     secret_key = aws_iam_access_key.pentester.secret
#   }
#   sensitive = true
# }