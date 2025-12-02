# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "${var.environment_name}-db-subnet-group"
  description = "Subnet group for RDS instances"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "${var.environment_name}-DB-Subnet-Group"
  }
}

# DB Security Group
resource "aws_security_group" "db" {
  name        = "${var.environment_name}-db-sg"
  description = "Security group for RDS instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.app_server_security_group_id]
    description     = "MySQL access from application servers"
  }

  tags = {
    Name = "${var.environment_name}-DB-SecurityGroup"
  }
}

# RDS Instance (Multi-AZ enabled)
resource "aws_db_instance" "main" {
  identifier = "${var.environment_name}-mysql-db"

  # Engine Configuration
  engine               = "mysql"
  engine_version       = "8.0.37"
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  storage_type         = "gp3"
  storage_encrypted    = true

  # Database Configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Multi-AZ Configuration
  multi_az = true

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  # Backup Configuration
  backup_retention_period      = var.db_backup_retention_period
  backup_window                = "03:00-04:00"
  maintenance_window           = "sun:04:00-sun:05:00"
  
  # Logging
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  # Maintenance
  auto_minor_version_upgrade = true
  deletion_protection       = false
  skip_final_snapshot      = true
  final_snapshot_identifier = "${var.environment_name}-mysql-db-final-snapshot"

  tags = {
    Name        = "${var.environment_name}-MySQL-Primary"
    Environment = var.environment_name
  }
}