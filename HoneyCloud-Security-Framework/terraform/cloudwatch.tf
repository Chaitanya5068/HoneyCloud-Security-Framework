resource "aws_cloudwatch_log_group" "cowrie_logs" {
  name              = "/honeycloud/cowrie"
  retention_in_days = 7
}

resource "aws_cloudwatch_metric_alarm" "failed_logins_alarm" {
  alarm_name          = "failed-login-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedLoginCount"
  namespace           = "HoneyCloud"
  period              = 60
  statistic           = "Sum"
  threshold           = 10

  alarm_actions = [aws_sns_topic.alerts.arn]
}