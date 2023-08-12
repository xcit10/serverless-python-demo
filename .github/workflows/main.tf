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
    attribute_name = "id"
    key_type       = "HASH"
  }
}

resource "aws_lambda_layer_version" "py_utils" {
  filename         = "src/pyutils.zip"
  layer_name       = "data-store-layer"
  compatible_runtimes = ["python3.9"]
}

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

# Lambda functions
locals {
  function_config = [
    {
      name        = "get_products"
      description = "Get products Lambda function"
      handler     = "get_products.app.lambda_handler"
      src_path    = "src/get_products"
      policies    = ["DynamoDBReadPolicy"]
      method      = "GET"
      path        = "/products"
    },
    {
      name        = "get_product"
      description = "Get product Lambda function"
      handler     = "get_product.app.lambda_handler"
      src_path    = "src/get_product"
      policies    = ["DynamoDBReadPolicy"]
      method      = "GET"
      path        = "/products/{id}"
    },
    {
      name        = "put_product"
      description = "Put product Lambda function"
      handler     = "put_product.app.lambda_handler"
      src_path    = "src/put_product"
      policies    = ["DynamoDBWritePolicy"]
      method      = "PUT"
      path        = "/products/{id}"
    },
    {
      name        = "delete_product"
      description = "Delete product Lambda function"
      handler     = "delete_product.app.lambda_handler"
      src_path    = "src/delete_product"
      policies    = ["DynamoDBCrudPolicy"]
      method      = "DELETE"
      path        = "/products/{id}"
    },
  ]
}

resource "aws_lambda_function" "functions" {
  count      = length(local.function_config)
  function_name = local.function_config[count.index].name
  role             = aws_iam_role.lambda_execution.arn
  handler          = local.function_config[count.index].handler
  runtime          = "python3.9"
  description      = local.function_config[count.index].description

  code {
    filename = "${local.function_config[count.index].src_path}.zip"
  }

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

  # Attach policies based on function_config
  policy = data.aws_iam_policy_document.function_policies[count.index].json
}

data "aws_iam_policy_document" "function_policies" {
  count = length(local.function_config)

  dynamic "statement" {
    for_each = local.function_config[count.index].policies

    content {
      actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
      resources = [aws_dynamodb_table.table.arn]

      # Add more actions as needed
    }
  }
}

resource "aws_lambda_permission" "api_gateway_permissions" {
  count         = length(local.function_config)
  statement_id  = "AllowAPIGatewayInvoke-${local.function_config[count.index].name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions[count.index].function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "serverless-python-demo"
  description = "Serverless Python Demo API"
}

resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "products"
}

resource "aws_api_gateway_method" "methods" {
  count         = length(local.function_config)
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = local.function_config[count.index].method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integrations" {
  count           = length(local.function_config)
  rest_api_id     = aws_api_gateway_rest_api.api.id
  resource_id     = aws_api_gateway_resource.products.id
  http_method     = aws_api_gateway_method.methods[count.index].http_method
  integration_http_method = "POST"
  type            = "AWS_PROXY"
  uri             = aws_lambda_function.functions[count.index].invoke_arn
}

resource "aws_api_gateway_method_response" "method_responses" {
  count       = length(local.function_config)
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.methods[count.index].http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "integration_responses" {
  count       = length(local.function_config)
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.methods[count.index].http_method
  status_code = aws_api_gateway_method_response.method_responses[count.index].status_code
}

output "api_gateway_url" {
  value = aws_api_gateway_rest_api.api.invoke_url
}
