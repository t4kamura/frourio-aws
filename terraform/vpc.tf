resource "aws_vpc" "vpc" {
  cidr_block           = "20.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "false"
  tags                 = { Name = var.basename }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${var.basename}-ig" }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "20.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags              = { Name = "${var.basename}-public-subnet-1" }
}
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "20.0.2.0/24"
  availability_zone = "ap-northeast-1c"
  tags              = { Name = "${var.basename}-public-subnet-2" }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "20.0.3.0/24"
  availability_zone = "ap-northeast-1a"
  tags              = { Name = "${var.basename}-private-subnet-1" }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "20.0.4.0/24"
  availability_zone = "ap-northeast-1c"
  tags              = { Name = "${var.basename}-private-subnet-2" }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = { Name = "${var.basename}-public-route" }
}

resource "aws_route_table_association" "puclic" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route.id
}


resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${var.basename}-private-route" }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private_route.id
  nat_gateway_id         = aws_nat_gateway.private_db.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_nat_gateway" "private_db" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags          = { Name = "${var.basename}-private-db-nat-gateway" }
}

resource "aws_eip" "nat_gateway" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gateway]
  tags       = { Name = "${var.basename}-nat-gateway-eip" }
}

resource "aws_security_group" "public" {
  name   = "${var.basename}-public"
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${var.basename}-public" }
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private" {
  name   = "${var.basename}-private"
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${var.basename}-private" }
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name   = "${var.basename}-alb-sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.basename}-alb-sg" }
}
