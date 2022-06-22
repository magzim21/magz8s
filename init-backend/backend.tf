# Original: https://medium.com/clarusway/how-to-use-s3-backend-with-a-locking-feature-in-terraform-to-collaborate-more-efficiently-fa0ea70cf359

provider "aws" {
  # The same retion as your future backend bucket
  region = "us-west-1"
}
resource "aws_s3_bucket" "tf_remote_state" {
  # Must be unique. Copy this bucket name to your backend.
  bucket = "terraform-s3-backend-with-locking-magzim"
  lifecycle {
    prevent_destroy = true
  }
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
#locking part

resource "aws_dynamodb_table" "tf_remote_state_locking" {
  hash_key = "LockID"
  name = "terraform-s3-backend-locking"
  attribute {
    name = "LockID"
    type = "S"
  }
  billing_mode = "PAY_PER_REQUEST"
}