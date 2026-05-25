resource "aws_security_group" "db_sg" {
  name        = "vela-db-sg"
  description = "Allow Postgres inbound only from web tier"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.web_sg_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "vela-db-subnet"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "main" {
  identifier                 = "vela-db"
  engine                     = "postgres"
  engine_version             = "15" # Hardcoded to bypass IAM permissions!
  instance_class             = "db.t3.micro"
  allocated_storage          = 20
  storage_type               = "gp3"
  db_name                    = "veladb"
  username                   = var.db_username
  password                   = var.db_password
  db_subnet_group_name       = aws_db_subnet_group.main.name
  vpc_security_group_ids     = [aws_security_group.db_sg.id]
  publicly_accessible        = false
  multi_az                   = false
  skip_final_snapshot        = true
  auto_minor_version_upgrade = true
}