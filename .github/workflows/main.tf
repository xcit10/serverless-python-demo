# Main tf for serverless app

# AWS account on us-east-1
provider "aws" {
    profile = "Avishay-WideOps"
    region = "us-east-1"
}

#aws ec2 describe-instances
terraform {
  backend "s3" {
    bucket = "terraform-back-tfstate"
    key = "tfstate-demo-app"
    region = "us-east-1"
  }
}

# dynamodb following https://registry.terraform.io/modules/terraform-aws-modules/dynamodb-table/aws/latest
module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"

  name     = "avishay-table"
  hash_key = "id"

  attributes = [
    {
      name = "id"
      type = "N"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "staging"
  }
}

# Lambda from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function.html#example-usage
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_role_product" {
  name               = "iam_for_lambda123"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Lambda Function - delete_product
data "archive_file" "delete_product" {
  type        = "zip"
  source_dir  = "${path.module}/src/delete_product"
  output_path = "${path.module}/myzip/delete_product.zip"
}
resource "aws_lambda_function" "delete_product" {
  filename                       = "${path.module}/myzip/delete_product.zip"
  function_name                  = "delete_product"
  role                           = aws_iam_role.iam_role_product.arn
  handler                        = "app.lambda_handler"
  runtime                        = "python3.9"
 # depends_on                     = [aws_iam_role_policy_attachment.policy_attach]
}

# Lambda Function - get_products
data "archive_file" "get_products" {
  type        = "zip"
  source_dir  = "${path.module}/src/get_products"
  output_path = "${path.module}/myzip/get_products.zip"
}
resource "aws_lambda_function" "get_products" {
  filename                       = "${path.module}/myzip/get_products.zip"
  function_name                  = "get_products"
  role                           = aws_iam_role.iam_role_product.arn
  handler                        = "app.lambda_handler"
  runtime                        = "python3.9"
 # depends_on                     = [aws_iam_role_policy_attachment.policy_attach]
}

# Lambda Function - get_product
data "archive_file" "get_product" {
  type        = "zip"
  source_dir  = "${path.module}/src/get_product"
  output_path = "${path.module}/myzip/get_product.zip"
}
resource "aws_lambda_function" "get_product" {
  filename                       = "${path.module}/myzip/get_product.zip"
  function_name                  = "get_product"
  role                           = aws_iam_role.iam_role_product.arn
  handler                        = "app.lambda_handler"
  runtime                        = "python3.9"
 # depends_on                     = [aws_iam_role_policy_attachment.policy_attach]
}

# Lambda Function - put_product
data "archive_file" "put_product" {
  type        = "zip"
  source_dir  = "${path.module}/src/put_product"
  output_path = "${path.module}/myzip/put_product.zip"
}
resource "aws_lambda_function" "put_product" {
  filename                       = "${path.module}/myzip/put_product.zip"
  function_name                  = "put_product"
  role                           = aws_iam_role.iam_role_product.arn
  handler                        = "app.lambda_handler"
  runtime                        = "python3.9"
 # depends_on                     = [aws_iam_role_policy_attachment.policy_attach]
}
