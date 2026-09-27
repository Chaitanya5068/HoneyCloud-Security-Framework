data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/threat_detector.py"
  output_path = "${path.module}/lambda/threat_detector.zip"
}

resource "aws_lambda_function" "threat_detector" {
  function_name = "honeycloud-threat-detector"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role    = aws_iam_role.lambda_role.arn
  handler = "threat_detector.lambda_handler"
  runtime = "python3.10"

  timeout = 30
}