output "db_endpoint" {
  # Strip the port from the endpoint so it's usable as a hostname
  value = split(":", aws_db_instance.main.endpoint)[0]
}
