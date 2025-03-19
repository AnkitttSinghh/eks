# Configure the AWS provider
# Specifies the AWS region and locks the provider version to 5.x
provider "aws" {
  version = "~> 5.0"
  region  = "us-west-2"
}

# Creates an S3 bucket for storing Terraform state
# Lifecycle block is used to control resource behavior:
# - 'prevent_destroy' is set to false, allowing the resource to be deleted during 'terraform destroy'
# - This setting can be changed to true to safeguard critical resources from accidental deletion
# - Lifecycle settings can also include 'ignore_changes' to exclude specific attributes from updates,
#   or 'create_before_destroy' to ensure replacements are handled safely

resource "aws_s3_bucket" "example" {
  bucket = "demo-terraform-eks-state-bucket-ankit"

  lifecycle {
    prevent_destroy = false
  }
}

# Create a DynamoDB table
resource "aws_dynamodb_table" "example" {
  name           = "ankit-terraform-eks-state-lock"            # The name of the DynamoDB table
  billing_mode   = "PAY_PER_REQUEST"                           # Choose "PROVISIONED" or "PAY_PER_REQUEST" for billing
  hash_key       = "Lock_ID"                                   # The primary key (partition key) for the table

  # Define the attribute schema for the table
  attribute {
    name = "Lock_ID"                               # The name of the primary key attribute
    type = "S"                                # The data type: "S" (string), "N" (number), or "B" (binary)
  }

}
