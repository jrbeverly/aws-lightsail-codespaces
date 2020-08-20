provider "aws" {
  region = local.region
}

locals {
  name = "codespace"
  domain  = "jrbeverly.dev"
  region  = "ca-central-1"
  availability_zone  = "ca-central-1b"
}

resource "aws_lightsail_instance" "app" {
  name              = "${local.name}.${local.domain}"
  blueprint_id      = "ubuntu_18_04"
  bundle_id         = "micro_2_0"
  key_pair_name     = local.keyname
  availability_zone = local.availability_zone
}


resource "aws_lightsail_static_ip_attachment" "app" {
  static_ip_name = aws_lightsail_static_ip.app.name
  instance_name  = aws_lightsail_instance.app.name
}

resource "aws_lightsail_static_ip" "app" {
  name = local.name
}

