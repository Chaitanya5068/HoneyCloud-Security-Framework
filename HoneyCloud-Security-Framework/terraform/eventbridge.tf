resource "aws_cloudwatch_event_rule" "threat_rule" {
  name        = "honeypot-threat-rule"
  description = "Trigger Lambda on threat detection"

  event_pattern = jsonencode({
    source = ["aws.cloudwatch"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.threat_rule.name
  target_id = "ThreatLambda"

  arn = aws_lambda_function.threat_detector.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.threat_detector.function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.threat_rule.arn
}