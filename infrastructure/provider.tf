locals {
  region  = "ca-central-1"
  profile = "default"
}
provider "aws" {
  region = local.region
}
