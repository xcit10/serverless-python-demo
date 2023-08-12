# main.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "table" {
  name           = "your-table-name"
  billing_mode   = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }

  key_schema {
    attribute_name = ${{ secrets.AWS_SECRET_KEY_ID }}
    key_type       = ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  }
}

resource "aws_lambda_layer_version" "py_utils" {
  filename         = "src/pyutils.zip"
  layer_name       = "data-store-layer"
  compatible_runtimes = ["python3.9"]
}
