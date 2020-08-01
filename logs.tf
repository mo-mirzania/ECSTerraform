### Creating log group for app
resource "aws_cloudwatch_log_group" "mohi_app_lg" {
  name              = "/ecs/app"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_stream" "mohi_app_ls" {
  log_group_name    = aws_cloudwatch_log_group.mohi_app_lg.id
  name              = "mohi_log_stream"
}