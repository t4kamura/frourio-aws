resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.basename}/database_url"
  value = "uninitialized"
  type  = "SecureString"

  lifecycle {
    ignore_changes = [value]
  }
}
