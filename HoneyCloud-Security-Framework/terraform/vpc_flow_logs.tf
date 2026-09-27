resource "aws_iam_role" "flow_logs_role" {
  name = "honeycloud-flowlogs-role"

  assume_role_policy = file("${path.module}/policies/flow_logs_assume_role.json")
}

resource "aws_iam_role_policy" "flow_logs_policy" {
  name = "honeycloud-flowlogs-policy"
  role = aws_iam_role.flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "vpc_logs" {
  name = "/aws/vpc/flowlogs"
}

resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_logs.arn

  traffic_type = "ALL"

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "HoneyCloud VPC Flow Logs"
  }
}