output "name" {
  value = local.name
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