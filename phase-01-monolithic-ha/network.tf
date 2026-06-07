# --- VPC & INTERNET GATEWAY ---
# trivy:ignore:AWS-0178
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "phase1-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "phase1-igw" }
}

# --- SUBNETS (Multi-AZ) ---
# Public Subnets (Tier 1 - Load Balancer)
resource "aws_subnet" "public_3a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-3a"
  map_public_ip_on_launch = true
  tags                    = { Name = "phase1-public-3a" }
}

resource "aws_subnet" "public_3b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-3b"
  map_public_ip_on_launch = true
  tags                    = { Name = "phase1-public-3b" }
}

# Private Application Subnets (Tier 2 - EC2 Instances)
resource "aws_subnet" "private_app_3a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-southeast-3a"
  tags              = { Name = "phase1-private-app-3a" }
}

resource "aws_subnet" "private_app_3b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-southeast-3b"
  tags              = { Name = "phase1-private-app-3b" }
}

# Private Database Subnets (Tier 3 - RDS MySQL)
resource "aws_subnet" "private_db_3a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "ap-southeast-3a"
  tags              = { Name = "phase1-private-db-3a  " }
}

resource "aws_subnet" "private_db_3b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "ap-southeast-3b"
  tags              = { Name = "phase1-private-db-3b" }
}

# --- ROUTING ---
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "phase1-public-rt" }
}

resource "aws_route_table_association" "public_3a_assoc" {
  subnet_id      = aws_subnet.public_3a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_3b_assoc" {
  subnet_id      = aws_subnet.public_3b.id
  route_table_id = aws_route_table.public_rt.id
}

# --- SECURITY GROUPS (Least Privilege) ---
# SG 1: Application Load Balancer (Internet)
resource "aws_security_group" "alb_sg" {
  name        = "phase1-alb-sg"
  description = "Allow public HTTP traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP traffic from the internet" # FIX AWS-0124
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# trivy:ignore:AWS-0104
  egress {
    description = "Allow all outbound traffic" # FIX AWS-0124
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG 2: EC2 Application (only traffic from ALB)
resource "aws_security_group" "app_sg" {
  name        = "phase1-app-sg"
  description = "Allow traffic strictly from ALB SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTP traffic only from ALB" # FIX AWS-0124
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG 3: RDS Database (only traffic from EC2 App)
resource "aws_security_group" "db_sg" {
  name        = "phase1-db-sg"
  description = "Allow database access only from App SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow MySQL traffic only from App SG" # FIX AWS-0124
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  
  egress {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

}