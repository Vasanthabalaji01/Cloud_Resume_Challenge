provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "vasanth_portfolio" {
  bucket = "vasanth-portfolio"
  acl    = "private"
}

resource "aws_cloudfront_distribution" "portfolio_distribution" {
  origin {
    domain_name = aws_s3_bucket.vasanth_portfolio.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.vasanth_portfolio.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2"
  default_root_object = "index.html"

  price_class = "PriceClass_All"

  aliases = []

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.vasanth_portfolio.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_dynamodb_table" "cloud_resume" {
  name         = "cloud-resume"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "N"
  }

  attribute {
    name = "views"
    type = "N"
  }
}

resource "aws_lambda_function" "cloud_portfolio_api" {
  filename      = "cloud-portfolio-api.zip"
  function_name = "cloud-portfolio-api"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.8"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.cloud_resume.name
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}
