#############################################################################
# VARIABLES
#############################################################################

variable "region" {
  type = string
  default = "us-east-2"
}

#############################################################################
# PROVIDERS
#############################################################################

provider "aws" {
  region = var.region
}

#############################################################################
# DATA SOURCES
#############################################################################

data "aws_iam_role" "existing_lambda_role" {
  name = "production.lambda-execute.role"
}

#############################################################################
# RESOURCES
#############################################################################  

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "apiDotnet-Function"
  description   = "API lambda function written in .NET"
  handler       = "apiDotnet.Function::apiDotnet.Function.LambdaEntryPoint::FunctionHandlerAsync"
  runtime       = "dotnet8"
  create_role   = false
  #lambda_role  = aws_iam_role.lambda_role.arn
  lambda_role   = data.aws_iam_role.existing_lambda_role.arn
  tracing_mode  = "Active"
  publish       = true
  architectures = ["arm64"]

  source_path = [{
    path = "../../src"
    commands = [
      "dotnet restore",
      "dotnet publish -c Release -r linux-arm64 -o publish",
      "cd ./publish",
      ":zip"
    ]
  }]

  environment_variables = {
    ENV = "dev"
  }

  #attach_policy_statements = true
  #policy_statements = {
  #  cloud_watch = {
  #    effect    = "Allow",
  #    actions   = ["cloudwatch:PutMetricData"],
  #    resources = ["*"]
  #  }
  #}
  
  tags = {
    Name        = "apiDotnet-Function"
    Environment = "Sandbox"
    Repository  = "https://github.com/CurtisLawhorn/apiDotnet.Function"
  }
}

#resource "aws_iam_role" "lambda_role" {
#  name = "production.lambda-execute2.role"
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [{
#      Action = "sts:AssumeRole",
#      Effect = "Allow",
#      Principal = {
#        Service = "lambda.amazonaws.com",
#      },
#    }],
#  })
#}

#resource "aws_iam_policy" "lambda_policy" {
#  name   = "lambda_policy"
#  policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [{
#      Action = [
#        "logs:CreateLogGroup",
#        "logs:CreateLogStream",
#        "logs:PutLogEvents",
#      ],
#      Effect   = "Allow",
#      Resource = "*",
#      #Resource = "arn:aws:logs:*:*:*",
#    }],
#  })
#}

#resource "aws_iam_role_policy_attachment" "lambda_logs" {
#  #role      = aws_iam_role.lambda_role.name
#  role       = data.aws_iam_role.existing_lambda_role.name
#  policy_arn = aws_iam_policy.lambda_policy.arn
#}

#############################################################################
# OUTPUTS
#############################################################################

