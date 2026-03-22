# Phase 1: Local backend. Migrate to S3 backend when needed.
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
