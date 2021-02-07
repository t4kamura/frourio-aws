resource "aws_ecr_repository" "api" {
  name                 = "${var.basename}-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.basename}-cluster"
}

resource "aws_ecs_service" "ecs_service" {
  name                              = "${var.basename}-service"
  cluster                           = aws_ecs_cluster.ecs_cluster.id
  task_definition                   = aws_ecs_task_definition.task_definition.arn
  desired_count                     = "1"
  launch_type                       = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups  = [aws_security_group.public.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "${var.basename}-api"
    container_port   = 8080
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  depends_on = [aws_lb_target_group.main]
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "${var.basename}-api"
  cpu                      = 256
  memory                   = 512
  container_definitions    = data.template_file.api_task_difinition.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
}

data "template_file" "api_task_difinition" {
  template = file("./taskdef.json")

  vars = {
    basename       = var.basename
    database_url   = aws_ssm_parameter.database_url.name
    api_origin     = "https://frourio.${var.domain}"
    ecr_api_url    = aws_ecr_repository.api.repository_url
    logs_group_api = "/${var.basename}/ecs_app/api"
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/${var.basename}/ecs_app/api"
  retention_in_days = 180
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.basename}_ecs_task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ecs_task_execution_role_policy_base" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ssm" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy_base.policy

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_task_execution_role_policy" {
  name   = "${var.basename}-task-execution-policy"
  policy = data.aws_iam_policy_document.ssm.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_role_policy.arn
}
