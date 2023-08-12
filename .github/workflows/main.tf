# main.tf
provider "aws" {
  region = "us-east-1"  # Change this to your desired region
}

resource "aws_dynamodb_table" "table" {
  name           = "avishay's-table-dynamodb"
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
  filename         = "src/pyutils/utils.py"
  layer_name       = "data-store-layer"
  compatible_runtimes = ["python3.9"]
}

resource "aws_lambda_function" "get_products" {
  filename         = "src/get_products/app.py"
  function_name    = "get-products-api"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.9"

  environment {
    variables = {
      TABLE                     = aws_dynamodb_table.table.name
      LOG_LEVEL                 = "INFO"
      POWERTOOLS_LOGGER_SAMPLE_RATE = "0.1"
      POWERTOOLS_LOGGER_LOG_EVENT   = "true"
      POWERTOOLS_METRICS_NAMESPACE  = "ServerlessPythonDemo"
      POWERTOOLS_SERVICE_NAME      = "api-service"
    }
  }

  layers = [aws_lambda_layer_version.py_utils.arn]
}

# Repeat the above block for other Lambda functions (GetProduct, PutProduct, DeleteProduct)

resource "aws_iam_role" "lambda_execution" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_lambda_permission" "get_products_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_products.function_name
  principal     = "apigateway.amazonaws.com"
}

# Repeat the above block for other Lambda permissions (GetProduct, PutProduct, DeleteProduct)

resource "aws_api_gateway_rest_api" "api" {
  name        = "serverless-python-demo"
  description = "Serverless Python Demo API"
}

resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "products"
}

resource "aws_api_gateway_method" "get_products" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_products" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.get_products.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_products.invoke_arn
}

resource "aws_api_gateway_method_response" "get_products" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.get_products.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "get_products" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.get_products.http_method
  status_code = aws_api_gateway_method_response.get_products.status_code
}

# Repeat the above block for other API Gateway resources and methods

output "api_gateway_url" {
  value = aws_api_gateway_rest_api.api.invoke_url
}
