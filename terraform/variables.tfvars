# AWS Configuration
aws_region = "us-east-1"
environment_name = "it-infra-ca2"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnet_cidrs = ["10.0.2.0/24", "10.0.3.0/24"]
availability_zones = ["us-east-1a", "us-east-1b"]

# Database Configuration
db_instance_class = "db.t3.medium"
db_name = "applicationdb"
db_username = "admin"
db_password = "YourSecurePassword123!"  # Change this!
db_allocated_storage = 20
db_backup_retention_period = 7

# Application Configuration
instance_type = "t3.medium"
key_name = "it-infra-ca2-key"  # Change this!
min_size = 2
max_size = 6
desired_capacity = 2
health_check_grace_period = 300