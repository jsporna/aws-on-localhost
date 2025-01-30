variable "application_name" {
  type = string
}

resource "aws_dynamodb_table" "application" {
  name = var.application_name

  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "file_path"
  range_key = "file_name"

  attribute {
    name = "file_path"
    type = "S"
  }

  attribute {
    name = "file_name"
    type = "S"
  }
}
