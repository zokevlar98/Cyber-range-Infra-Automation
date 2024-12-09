resource "aws_iam_user" "pentester_user" {
  name = "cr-pentester-${var.crid}"
  tags = {
    deployment_profile = var.profile_pentester
  }
}

# Create access key for pentester user
resource "aws_iam_access_key" "pentester" {
  user = aws_iam_user.pentester_user.name
}

resource "aws_iam_user_policy" "pentester_policy" {
  name = "pentester-limited-policy"
  user = aws_iam_user.pentester_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = ""
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        # Resource = "arn:aws:iam::940877411605:role/cr-lambda-invoker*"
        Resource = "*"
      },
      {
        Sid    = ""
        Effect = "Allow"
        Action = [
          "iam:Get*",
          "iam:List*",
          "iam:SimulateCustomPolicy",
          "iam:SimulatePrincipalPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "cr-lambda-invoker" {
  name = "cr-lambda-invoker-${var.crid}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = aws_iam_user.pentester_user.arn
        }
      }
    ]
  })
}
resource "aws_iam_policy" "cr-lambda-invoker" {
  name = "lambda-invoker"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:ListFunctionEventInvokeConfigs",
          "lambda:InvokeFunction",
          "lambda:ListTags",
          "lambda:GetFunction",
          "lambda:GetPolicy"
        ]
        Resource = aws_lambda_function.policy_applier_lambda1.arn
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:ListFunctions",
          "iam:Get*",
          "iam:List*",
          "iam:SimulateCustomPolicy",
          "iam:SimulatePrincipalPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_invoker_policy_attachment" {
  role       = aws_iam_role.cr-lambda-invoker.name
  policy_arn = aws_iam_policy.cr-lambda-invoker.arn
}