resource "aws_iam_role" "sagemaker_role" {
  name = "honeycloud-sagemaker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_policy" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_sagemaker_notebook_instance" "ml_notebook" {
  name          = "honeycloud-ml"
  role_arn      = aws_iam_role.sagemaker_role.arn
  instance_type = "ml.t2.medium"

  tags = {
    Name = "HoneyCloud SageMaker"
  }
}