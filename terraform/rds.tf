resource "aws_db_subnet_group" "db_subnet_group" {
  name = "${var.basename}-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
  tags = { Name = "${var.basename}-db-subnet-group" }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.basename}-postgres"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "12"
  instance_class         = "db.t2.micro"
  name                   = "frourio"
  username               = "postgres"
  password               = "uninitialized"
  vpc_security_group_ids = [aws_security_group.private.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot    = true

  lifecycle {
    ignore_changes = [password, engine_version]
  }
}
