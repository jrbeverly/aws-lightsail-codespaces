locals {
  region  = "ca-central-1"
  profile = "home"
}
provider "aws" {
  region = local.region
}
