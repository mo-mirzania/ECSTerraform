variable "aws_region" {
  description = "AWS Region"
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "ECS Fargate VPC CIDR"
  default     = "10.123.0.0/16"
}

variable "app_image" {
  default = "momirzania/sys:aws"
  description = "N26 challenge app address"
}

variable "app_port" {
  default = "8080"
  description = "App's listening port"
}

variable "app_cpu" {
  default = "1024"
  description = "CPU units for Spring app - 1024 equals to 1 vcpu"
}

variable "app_memory" {
  default = "2048"
  description = "Memory in MB for Spring app"
}

variable "pg_image" {
  default = "postgres"
  description = "Postgres docker image address"
}

variable "pg_port" {
  default = "5432"
  description = "Postgres listening port"
}

variable "pg_cpu" {
  default = "256"
  description = "CPU units for Postgres container - 1024 equals to 1 vcpu"
}

variable "pg_memory" {
  default = "512"
  description = "Memory in MB for Postgres container"
}

variable "app_count" {
  default = "1"
  description = "Number of app's containers"
}

variable "pg_count" {
  default = "1"
  description = "Number of Postgres containers"
}

variable "ecs_task_execution_role_name" {
  default = "myEcsTaskExecutionRole"
  description = "ECS task execution role name"
}

variable "max_capacity" {
  default = "3"
  description = "App's maximum capacity in auto-scaling"
}

variable "min_capacity" {
  default = "1"
  description = "App's minimum capacity in auto-scaling"
}
