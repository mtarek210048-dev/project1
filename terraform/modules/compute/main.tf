
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Allow HTTP and HTTPS inbound to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-alb-sg", Project = var.project_name }
}

# App SG — accepts traffic only from ALB SG
resource "aws_security_group" "app" {
  name = "${var.project_name}-${var.environment}-app-sg"
  description = "Allow traffic from ALB only"
  vpc_id = var.vpc_id

  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    security_groups = [aws_security_group.alb.id]
    description = "App traffic from ALB"
  }

  egress {
    from_port= 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-app-sg", Project = var.project_name }
}


resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "s3-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
      Resource = ["arn:aws:s3:::${var.s3_bucket_name}", "arn:aws:s3:::${var.s3_bucket_name}/*"]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}


data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix = "${var.project_name}-${var.environment}-lt-"
  image_id = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name = var.key_name != "" ? var.key_name : null

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups  = [aws_security_group.app.id]
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_endpoint = var.db_endpoint
    db_name = var.db_name
    db_username = var.db_username
    db_password = var.db_password
    s3_bucket = var.s3_bucket_name
    PORT  = 3000
    aws_region  = var.aws_region
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name  = "${var.project_name}-${var.environment}-app"
      Project = var.project_name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_lb" "main" {
  name = "${var.project_name}-${var.environment}-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb.id]
  subnets = var.public_subnet_ids

  tags = { Name = "${var.project_name}-${var.environment}-alb", Project = var.project_name }
}

resource "aws_lb_target_group" "app" {
  name = "${var.project_name}-${var.environment}-tg"
  port = 3000
  protocol = "HTTP"
  vpc_id = var.vpc_id

  health_check {
    path = "/health"
    interval = 30
    timeout = 5
    healthy_threshold  = 2
    unhealthy_threshold = 3
    matcher = "200"
  }

  tags = { Project = var.project_name }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_autoscaling_group" "app" {
  name = "${var.project_name}-${var.environment}-asg"
  desired_capacity = 2
  min_size  = 1
  max_size = 4
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns  = [aws_lb_target_group.app.arn]
  health_check_type  = "ELB"

  launch_template {
    id  = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key  = "Name"
    value  = "${var.project_name}-${var.environment}-app"
    propagate_at_launch = true
  }
}


resource "aws_autoscaling_policy" "scale_out" {
  name = "scale-out"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = 1
  cooldown = 300
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  statistic = "Average"
  threshold = 70
  alarm_actions = [aws_autoscaling_policy.scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}
