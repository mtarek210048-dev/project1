# ──────────────────────────────────────────
# RDS Security Group
# ──────────────────────────────────────────
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Allow MySQL traffic from app servers only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.app_sg_id]
    description     = "MySQL from app tier"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-rds-sg", Project = var.project_name }
}

# ──────────────────────────────────────────
# DB Subnet Group (requires subnets in 2 AZs)
# ──────────────────────────────────────────
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.project_name}-${var.environment}-db-subnet-group", Project = var.project_name }
}

# ──────────────────────────────────────────
# RDS MySQL Instance
# ──────────────────────────────────────────
resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-${var.environment}-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # For dev — disable multi-AZ and backups to save cost
  multi_az               = false
  backup_retention_period = 0
  skip_final_snapshot    = true
  deletion_protection    = false

  publicly_accessible = false

  tags = { Name = "${var.project_name}-${var.environment}-db", Project = var.project_name }
}
