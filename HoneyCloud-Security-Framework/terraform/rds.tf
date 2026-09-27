resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "honeycloud-rds-subnet-group"

  subnet_ids = [
    aws_subnet.public.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name = "HoneyCloud RDS Subnet Group"
  }
}

resource "aws_security_group" "rds_sg" {
  name   = "honeycloud-rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "decoy_db" {
  identifier        = "honeycloud-decoy-db"
  allocated_storage = 20
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"

  username = "admin"
  password = "Password123!"

  publicly_accessible = true

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true

  tags = {
    Name = "decoy-rds"
  }
}