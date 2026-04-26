output "db_endpoint" {
  value = split(":", aws_db_instance.main.endpoint)[0]
}
