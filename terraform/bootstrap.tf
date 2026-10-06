resource "aws_s3_bucket" "terraform_state" {
  bucket = "infra-as-code-pipeline-terraform-state-09-rs"

  tags = {
    Name      = "infra-as-code-pipeline-terraform-state"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "infra-as-code-pipeline-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "infra-as-code-pipeline-terraform-locks"
    ManagedBy = "Terraform"
  }
}