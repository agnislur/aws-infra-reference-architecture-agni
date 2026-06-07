resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "phase1-db-subnet-group"
  subnet_ids = [aws_subnet.private_db_3a.id, aws_subnet.private_db_3b.id]
  tags       = { Name = "phase1-db-subnet-group" }
}

resource "aws_db_instance" "main_db" {
  allocated_storage      = 20
  max_allocated_storage  = 100
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro" 
  identifier             = "phase1-portfolio-db"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  multi_az               = false 
  
  skip_final_snapshot    = true
}