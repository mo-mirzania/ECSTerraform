resource "aws_appautoscaling_target" "app" {
  max_capacity              = var.max_capacity
  min_capacity              = var.min_capacity
  resource_id               = "service/${aws_ecs_cluster.mohi.name}/${aws_ecs_service.mohi_app_service.name}"
  scalable_dimension        = "ecs:service:DesiredCount"
  service_namespace         = "ecs"
}


### Scaling out app's capacity by one, when average cpu usage is above 80%
resource "aws_appautoscaling_policy" "increase_capacity" {
  name                      = "app_scale_out"
  resource_id               = aws_appautoscaling_target.app.resource_id
  scalable_dimension        = aws_appautoscaling_target.app.scalable_dimension
  service_namespace         = aws_appautoscaling_target.app.service_namespace
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown = 60
    metric_aggregation_type = "Maximum"
    step_adjustment {
      scaling_adjustment    = 1
      metric_interval_lower_bound = "1"
    }
  }
}

### Scaling in app's capacity by one, when average cpu usage is below 40%
resource "aws_appautoscaling_policy" "decrease_capacity" {
  name                      = "app_scale_down"
  resource_id               = aws_appautoscaling_target.app.resource_id
  scalable_dimension        = aws_appautoscaling_target.app.scalable_dimension
  service_namespace         = aws_appautoscaling_target.app.service_namespace
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"
    step_adjustment {
      scaling_adjustment    = -1
      metric_interval_upper_bound = 0
    }
  }
}

### Scaling out trigger
resource "aws_cloudwatch_metric_alarm" "app_high_cpu" {
  alarm_name                = "mohi_app_high_cpu"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  dimensions = {
    ClusterName             = aws_ecs_cluster.mohi.name
    ServiceName             = aws_ecs_service.mohi_app_service.name
  }
  alarm_actions             = [aws_appautoscaling_policy.increase_capacity.arn]
}

### Scaling in trigger
resource "aws_cloudwatch_metric_alarm" "app_low_cpu" {
  alarm_name                = "mohi_app_low_cpu"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "40"
  dimensions = {
    ClusterName             = aws_ecs_cluster.mohi.name
    ServiceName             = aws_ecs_service.mohi_app_service.name
  }
  alarm_actions             = [aws_appautoscaling_policy.decrease_capacity.arn]
}
