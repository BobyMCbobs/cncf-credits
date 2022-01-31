// terraform config //
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  # backend "s3" {
  #   bucket  = "cncf-credits-infra-kubernetes-tfstate"
  #   key     = "terraform.tfstate"
  #   region  = "ap-southeast-2"
  #   encrypt = true
  # }
}

provider "aws" {
  profile = "default"
  region  = "ap-southeast-2"
}
// ---------------- //

// the tfstate for the management of the kubernetes account+OU //
resource "aws_kms_key" "cncf-credits-infra-kubernetes-tfstate" {
  description = "This key is used to encrypt bucket objects"
}
resource "aws_s3_bucket" "cncf-credits-infra-kubernetes-tfstate" {
  bucket = "cncf-credits-infra-kubernetes-tfstate"
  acl    = "private"

  lifecycle {
    prevent_destroy = true
  }

  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.cncf-credits-infra-kubernetes-tfstate.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
resource "aws_s3_bucket_ownership_controls" "cncf-credits-infra-kubernetes-tfstate" {
  bucket = aws_s3_bucket.cncf-credits-infra-kubernetes-tfstate.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_public_access_block" "cncf-credits-infra-kubernetes-tfstate" {
  bucket = aws_s3_bucket.cncf-credits-infra-kubernetes-tfstate.id

  block_public_acls   = true
  block_public_policy = true
}
// ----------------------------------------------------------- //

// creating the org //
resource "aws_organizations_organization" "kubernetes" {
  feature_set = "ALL"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "kubernetes" {
  name                       = "kubernetes"
  email                      = "k8s-infra-aws-root-account@kubernetes.io"
  iam_user_access_to_billing = "ALLOW"
  parent_id                  = aws_organizations_organization.kubernetes.id

  lifecycle {
    prevent_destroy = true
  }
}
// ---------------- //
