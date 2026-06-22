# providers.tf — tells Terraform which tools it needs and how to reach AWS.

terraform {
  # use_lockfile (native S3 state locking) needs Terraform >= 1.10.
  required_version = ">= 1.10"

  # The plugins ("providers") Terraform downloads during `terraform init`.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # any 5.x version
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0" # used to zip our Lambda code
    }
  }

  # Store state remotely in S3 instead of on the local laptop.
  #   - bucket/key: where the state file lives inside the bucket
  #   - encrypt: encrypt the state at rest
  #   - use_lockfile: native S3 locking so two applies can't clash
  # NOTE: backend settings must be literal values (no variables allowed here).
  backend "s3" {
    bucket       = "trend-tracker-tfstate-804838453270"
    key          = "global/hello/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}

# Configure the AWS provider. It picks up your credentials automatically
# from the `aws configure` you ran earlier (~/.aws/credentials).
provider "aws" {
  region = var.aws_region
}
