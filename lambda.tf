# IAM Role for policy_applier_lambda1
resource "aws_iam_role" "policy_applier_lambda1" {
  name = "${var.crid}-policy_applier_lambda1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

# Policy for policy_applier_lambda1
resource "aws_iam_role_policy" "policy_applier_lambda1_policy" {
  name = "policy_applier_lambda1"
  role = aws_iam_role.policy_applier_lambda1.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "iam:AttachUserPolicy"
        Effect   = "Allow"
        Resource = aws_iam_user.pentester_user.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.crid}-policy_applier_lambda1:*"
      }
    ]
  })
}

# Archive the source code for the Lambda function
data "archive_file" "policy_applier_lambda1_zip" {
  type        = "zip"
  source_dir  = "lambda_source_code/policy_applier_lambda1_src"
  output_path = "lambda_source_code/archives/policy_applier_lambda1_src.zip"
}

# CloudWatch Log Group for the Lambda function
resource "aws_cloudwatch_log_group" "policy_applier_lambda1" {
  name              = "/aws/lambda/${var.crid}-policy_applier_lambda1"
  retention_in_days = 14
}

# Lambda function for policy_applier_lambda1
resource "aws_lambda_function" "policy_applier_lambda1" {
  depends_on = [
    aws_cloudwatch_log_group.policy_applier_lambda1
  ]

  filename         = data.archive_file.policy_applier_lambda1_zip.output_path
  function_name    = "${var.crid}-policy_applier_lambda1"
  role             = aws_iam_role.policy_applier_lambda1.arn
  handler          = "main.handler"
  description      = "This function will apply a managed policy to the user of your choice, so long as the database says that it's okay..."
  source_code_hash = filebase64sha256(data.archive_file.policy_applier_lambda1_zip.output_path)
  runtime          = "python3.9"
}
