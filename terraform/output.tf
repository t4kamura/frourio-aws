output "db_endpoint" {
  value = aws_db_instance.postgres.address
}

output "ecr_url" {
  value = aws_ecr_repository.api.repository_url
}
