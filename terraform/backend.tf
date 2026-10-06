terraform {
  backend "s3" {
    bucket         = "infra-as-code-pipeline-terraform-state-09-rs"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "infra-as-code-pipeline-terraform-locks"
    encrypt        = true
  }
}