# Archivo main.tf

# Configuración del proveedor AWS
provider "aws" {
  region = "us-east-1"  # Ajusta la región según tu preferencia
}

# Creación de la tabla de DynamoDB
resource "aws_dynamodb_table" "user_table" {
  name           = "user_table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  attribute {
    name = "user_id"
    type = "S"
  }
  # Otros atributos de la tabla de usuarios (nombre, temperatura, etc.)
  # ...

  # Índice global secundario (GSI) para buscar usuarios por nombre, por ejemplo
  global_secondary_index {
    name               = "name_index"
    hash_key           = "name"
    projection_type    = "ALL"
    read_capacity      = 5
    write_capacity     = 5
    # Otros atributos indexados (temperatura, fecha de registro, etc.)
    # ...
  }
}

# Creación del rol de IAM para la función Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  # Añade los permisos necesarios para acceder a los recursos requeridos
  # ...
}

# Creación de la función Lambda
resource "aws_lambda_function" "backend_lambda" {
  function_name = "backend_lambda"
  runtime       = "python3.9"  # Ajusta según tu lenguaje de preferencia
  handler       = "handler.lambda_handler"
  # Código fuente de la función Lambda
  # ...

  # Configuración de variables de entorno para la función Lambda
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.user_table.name
    }
  }
}

# Creación de la API en API Gateway
resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "api_gateway"
  description = "API Gateway for the entry control system"
}

# Configuración de los endpoints en la API Gateway
resource "aws_api_gateway_resource" "users_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_method" "create_user_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.users_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Configuración de la integración entre API Gateway y la función Lambda
resource "aws_api_gateway_integration" "create_user_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.users_resource.id
  http_method             = aws_api_gateway_method.create_user_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.backend_lambda.invoke_arn
}

# Despliegue de la infraestructura en AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
