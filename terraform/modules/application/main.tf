# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Application Load Balancer Security Group
resource "aws_security_group" "alb" {
  name        = "${var.environment_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.environment_name}-ALB-SecurityGroup"
  }
}

# Application Server Security Group
resource "aws_security_group" "app_server" {
  name        = "${var.environment_name}-app-server-sg"
  description = "Security group for application servers"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "HTTP from ALB"
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "HTTPS from ALB"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "SSH from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.environment_name}-AppServer-SecurityGroup"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = var.public_subnet_ids

  tags = {
    Name = "${var.environment_name}-ALB"
  }
}

# Target Group
resource "aws_lb_target_group" "main" {
  name     = "${var.environment_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "${var.environment_name}-TargetGroup"
  }
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "${var.environment_name}-launch-template-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.app_server.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd mysql
    
    # Start and enable Apache
    systemctl start httpd
    systemctl enable httpd
    
    # Get instance metadata
    INSTANCE_ID=$(ec2-metadata --instance-id | cut -d ' ' -f 2)
    AZ=$(ec2-metadata --availability-zone | cut -d ' ' -f 2)
    
    # Create a simple test page
    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
    <head>
        <title>Application Server</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                margin: 50px;
                background-color: #f0f0f0;
            }
            .container {
                background-color: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            }
            h1 { color: #333; }
            .info { color: #666; margin: 10px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Application Server</h1>
            <div class="info"><strong>Instance ID:</strong> INSTANCE_ID_PLACEHOLDER</div>
            <div class="info"><strong>Availability Zone:</strong> AZ_PLACEHOLDER</div>
            <div class="info"><strong>Database Endpoint:</strong> ${var.db_endpoint}</div>
            <div class="info"><strong>Database Name:</strong> ${var.db_name}</div>
        </div>
    </body>
    </html>
    HTML
    
    # Replace placeholders
    sed -i "s/INSTANCE_ID_PLACEHOLDER/$INSTANCE_ID/" /var/www/html/index.html
    sed -i "s/AZ_PLACEHOLDER/$AZ/" /var/www/html/index.html
    
    # Create health check endpoint
    echo "OK" > /var/www/html/health.html
    
    # Database connection info
    cat > /var/www/html/db-info.txt <<DBINFO
    Database Endpoint: ${var.db_endpoint}
    Database Name: ${var.db_name}
    DBINFO
    
    # Set proper permissions
    chmod 644 /var/www/html/*
    chown apache:apache /var/www/html/*
    EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment_name}-App-Server"
      Environment = var.environment_name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = "${var.environment_name}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.main.arn]
  health_check_type   = "ELB"
  health_check_grace_period = var.health_check_grace_period

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment_name}-ASG-Instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment_name
    propagate_at_launch = true
  }

  depends_on = [aws_lb_listener.http]
}

# Auto Scaling Policy - CPU Target Tracking
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.environment_name}-cpu-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Auto Scaling Policy - ALB Request Count Target Tracking
resource "aws_autoscaling_policy" "alb_request_count" {
  name                   = "${var.environment_name}-alb-request-count-policy"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.main.arn_suffix}"
    }
    target_value = 1000.0
  }
}