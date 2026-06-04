variable "db_username" {
  type        = string
  description = "Username untuk administrator RDS"
}

variable "db_password" {
  type        = string
  description = "Password untuk administrator RDS"
  sensitive   = true
}