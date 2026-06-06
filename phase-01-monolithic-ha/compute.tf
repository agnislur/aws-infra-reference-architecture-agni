# --- APPLICATION LOAD BALANCER ---
resource "aws_lb" "app_alb" {
  name               = "phase1-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "app_tg" {
  name     = "phase1-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    port                = "80"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# --- AUTO SCALING GROUP & LAUNCH TEMPLATE ---
resource "aws_launch_template" "app_lt" {
  name_prefix   = "phase1-app-lt-"
  image_id      = "ami-01811d4912b4ccb26" # Ubuntu 22.04 LTS (ap-southeast-1)
  instance_type = "t3.micro"               # Free Tier Eligible

  network_interfaces {
    security_groups             = [aws_security_group.app_sg.id]
    associate_public_ip_address = false 
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "<h1>Hello World! Ini adalah halaman web High Availability Phase 1</h1>" > index.html
              python3 -m http.server 80 &
              EOF
  )
}

resource "aws_autoscaling_group" "app_asg" {
  name                = "phase1-app-asg"
  vpc_zone_identifier = [aws_subnet.private_app_1a.id, aws_subnet.private_app_1b.id]
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}