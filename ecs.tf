### Creating ECS cluster
resource "aws_ecs_cluster" "mohi" {
  name                      = "mohi_cluster"
}

### App's task definition file
data "template_file" "app" {
  template                  = file("./templates/app.json.tpl")
  vars = {
    app_image               = var.app_image
    app_port                = var.app_port
    app_cpu                 = var.app_cpu
    app_memory              = var.app_memory
    aws_region              = var.aws_region
  }
}

### Postgres' task definition file
data "template_file" "postgres" {
  template                  = file("./templates/postgres.json.tpl")
  vars = {
    pg_image                = var.pg_image
    pg_port                 = var.pg_port
    pg_cpu                  = var.pg_cpu
    pg_memory               = var.pg_memory
    aws_region              = var.aws_region
  }
}

### ECS task definition for app
resource "aws_ecs_task_definition" "app" {
  container_definitions     = data.template_file.app.rendered
  family                    = "mohi_app"
  execution_role_arn        = aws_iam_role.ecs_task_execution_role.arn
  network_mode              = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                       = var.app_cpu
  memory                    = var.app_memory
}

### ECS task definition for Postgres
resource "aws_ecs_task_definition" "postgres" {
  container_definitions     = data.template_file.postgres.rendered
  family                    = "mohi_postgres"
  execution_role_arn        = aws_iam_role.ecs_task_execution_role.arn
  network_mode              = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                       = var.pg_cpu
  memory                    = var.pg_memory
}

### ECS service definition for app
resource "aws_ecs_service" "mohi_app_service" {
  name                      = "app-service"
  task_definition           = aws_ecs_task_definition.app.id
  cluster                   = aws_ecs_cluster.mohi.id
  desired_count             = var.app_count
  launch_type               = "FARGATE"
  network_configuration {
    subnets                 = aws_subnet.mohi_private.*.id
    security_groups         = [aws_security_group.mohi_ecs.id]
    assign_public_ip        = true
  }
  load_balancer {
    container_name          = "app"
    container_port          = var.app_port
    target_group_arn        = aws_alb_target_group.mohi_alb_tg.id
  }
  depends_on                = [aws_alb_listener.mohi_sys_front, aws_iam_role_policy_attachment.ecs_task_execution_role]
}

### ECS service definition for Postgres
resource "aws_ecs_service" "mohi_postgres_service" {
  name                      = "postgres-service"
  task_definition           = aws_ecs_task_definition.postgres.id
  cluster                   = aws_ecs_cluster.mohi.id
  desired_count             = var.pg_count
  launch_type               = "FARGATE"
  network_configuration {
    subnets                 = aws_subnet.mohi_private.*.id
    security_groups         = [aws_security_group.mohi_postgres.id]
    assign_public_ip        = true
  }
  service_registries {
    registry_arn            = aws_service_discovery_service.postgres.arn
    container_name          = "postgres"
  }
}

