resource "aws_instance" "honeypot" {
  ami                    = "ami-091138d0f0d41ff90"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.honeypot_sg.id]
  key_name               = var.key_name

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = file("${path.module}/userdata/cowrie.sh")

  tags = {
    Name = "cowrie-honeypot"
  }
}