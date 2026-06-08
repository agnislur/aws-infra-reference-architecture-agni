# --- APPLICATION LOAD BALANCER ---
resource "aws_lb" "app_alb" {
  name               = "phase1-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_3a.id, aws_subnet.public_3b.id]
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "app_tg" {
  name     = "phase1-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    port                = "80"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}
# trivy:ignore:AWS-0054
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
# trivy:ignore:AWS-0053
resource "aws_launch_template" "app_lt" {
  name_prefix   = "phase1-app-lt-"
  image_id      = "ami-038788ccdf113ed0e" # Amazon Linux 2023 (ap-southeast-3)
  instance_type = "t3.micro"               # Free Tier Eligible

  network_interfaces {
    security_groups             = [aws_security_group.app_sg.id]
    associate_public_ip_address = true 
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring {
    enabled = true
  }

user_data = base64encode(<<-EOF
              #!/bin/bash
              
              # 1. Update OS dan Install Docker
              dnf update -y
              dnf install -y docker
              systemctl start docker
              systemctl enable docker
              # 2. Setup Direktori Aplikasi
              mkdir -p /home/ubuntu/app
              cd /home/ubuntu/app

              # 3. Buat file package.json untuk Node.js
              cat << 'APP_EOF' > package.json
              {
                "name": "ha-api-phase1",
                "version": "1.0.0",
                "main": "server.js",
                "dependencies": {
                  "express": "^4.18.2"
                }
              }
              APP_EOF

              # 4. Buat file server.js (Real-world API sederhana)
              cat << 'APP_EOF' > server.js
              const express = require('express');
              const app = express();
              const port = 80;

              // Endpoint Health Check: Sangat penting untuk AWS ALB Target Group
              app.get('/health', (req, res) => {
                  res.status(200).send('OK');
              });

              // Endpoint API utama: Mensimulasikan delay database
              app.get('/api/data', (req, res) => {
                  // Simulasi proses komputasi atau query DB selama 50ms
                  setTimeout(() => {
                      res.json({
                          message: "Hello dari Dockerized Node.js API!",
                          environment: "Production-Ready Phase 1",
                          timestamp: new Date().toISOString()
                      });
                  }, 50); 
              });

              app.listen(port, () => {
                  console.log(`App listening on port $${port}`);
              });
              APP_EOF

              # 5. Buat Dockerfile
              cat << 'APP_EOF' > Dockerfile
              # Gunakan image Alpine yang ringan
              FROM node:18-alpine
              WORKDIR /usr/src/app
              COPY package.json ./
              RUN npm install --production
              COPY server.js ./
              EXPOSE 80
              CMD [ "node", "server.js" ]
              APP_EOF

              # 6. Build dan Run Docker Container
              docker build -t phase1-api:latest .
              docker run -d -p 80:80 --name my-api --restart always phase1-api:latest
              EOF
  )
}

resource "aws_autoscaling_group" "app_asg" {
  name                = "phase1-app-asg"
  vpc_zone_identifier = [aws_subnet.public_3a.id, aws_subnet.public_3b.id]
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

resource "aws_autoscaling_policy" "app_cpu_scaling_policy" {
  name                   = "phase1-app-cpu-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}