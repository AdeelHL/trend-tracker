# variables.tf — inputs we can reuse instead of hard-coding values everywhere.

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Prefix for all resource names so they're easy to find"
  type        = string
  default     = "trend-tracker"
}

variable "github_repo" {
  description = "owner/repo allowed to assume the GitHub Actions deploy role"
  type        = string
  default     = "AdeelHL/trend-tracker"
}
