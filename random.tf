resource "random_id" "random" {
  byte_length = 4
}

resource "random_integer" "unique" {
  min = 100
  max = 999
}
resource "random_password" "password" {
  length           = 64
  special          = false
}