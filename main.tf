terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "gatiko-backend-s3"
    key = "dev/gatiko-state/terraform-tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}


#Zip

module "zip-email-confirmation" {
  source = "./modules/zip"
  file = "Email"
  folder = "cognito-emilConfirmation"
}
module "zip-posts-gatiko" {
  source = "./modules/zip"
  file = "Crud"
  folder = "crud-posts-gatiko"
}

#DynamoDB
module "gatiko-dynamo-db" {
  source = "./modules/dynamodb"
}

#Cognito

module "cognito" {
   source = "./modules/cognito"
   email_confirmation_arn = module.cognito-emilConfirmation.function_arn
   depends_on = [ module.cognito-emilConfirmation ]
   ses_arn = module.ses.ses_arn
}

#S3 Buckets

module "lambda-bucket" {
    source = "./modules/s3"
    name = "lambda-bucket"
}

#Lambda Modules

module "cognito-emilConfirmation" {
  source = "./modules/lambda"
  name = "cognito-emilConfirmation"
  bucket_id = module.lambda-bucket.bucket_id
  depends_on = [ module.gatiko-dynamo-db ]
  table_arn_dynamodb = module.gatiko-dynamo-db.dynamodb_table_arn
}

module "crud-posts-gatiko" {
  source = "./modules/lambda"
  name = "crud-posts-gatiko"
  bucket_id = module.lambda-bucket.bucket_id
  depends_on = [ module.gatiko-dynamo-db ]
  table_arn_dynamodb = module.gatiko-dynamo-db.dynamodb_table_arn
}

#SES service
module "ses" {
  source = "./modules/ses"
}

#AppSync
module "appsync-crud" {
  source = "./modules/appsync"
  lambda_arn = module.crud-posts-gatiko.function_arn
  depends_on = [ module.crud-posts-gatiko ]
}