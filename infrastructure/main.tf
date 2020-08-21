provider "aws" {
  region = local.region
}

resource "random_id" "random" {
  byte_length = 4
}

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}

locals {
  name              = "codespace-4321"
  domain            = "jrbeverly.dev"
  url               = "${local.name}.${local.domain}"
  region            = "ca-central-1"
  availability_zone = "ca-central-1a"
}

resource "aws_lightsail_instance" "app" {
  name              = local.url
  blueprint_id      = "ubuntu_18_04"
  bundle_id         = "micro_2_0"
  availability_zone = local.availability_zone
  tags = {
    name = local.name
    www  = local.url
    desc = "Cloud environment for running VSCode in the browser."
  }

  user_data = replace(replace(file("provision/prototype.sh"), "TF_DOMAIN_URL", local.url), "TF_PASSWORD", random_password.password.result)
}

## WORKAROUND
# Port configuration for the lightsail instance
locals {
  ports = [
    {
      fromPort = 22
      toPort   = 22
      protocol = "tcp"
    },
    {
      fromPort = 80
      toPort   = 80
      protocol = "tcp"
    },
    {
      fromPort = 443
      toPort   = 443
      protocol = "tcp"
    },
  ]
  public_ports = "${join(" ", [for s in local.ports : format("fromPort=%d,toPort=%d,protocol=%s", s.fromPort, s.toPort, s.protocol)])}"
}

resource "null_resource" "firewall" {
  depends_on = [aws_lightsail_instance.app]
  triggers = {
    public_ports = local.public_ports
    url          = local.url
  }

  // Workaround until terraform-provider-aws/issues/700 (aws_lightsail provider should support open port management)
  // has been resolved. For now use awscli to manually set these properties.
  provisioner "local-exec" {
    command = "aws lightsail put-instance-public-ports --instance-name=${local.url} --port-infos ${local.public_ports}"
  }
}

###

resource "aws_lightsail_static_ip_attachment" "app" {
  static_ip_name = aws_lightsail_static_ip.app.name
  instance_name  = aws_lightsail_instance.app.name
}

resource "aws_lightsail_static_ip" "app" {
  name = local.name
}


output "url" {
  value = local.url
}

output "ip_address" {
  value = aws_lightsail_static_ip.app.ip_address
}

output "password" {
  value = random_password.password.result
}