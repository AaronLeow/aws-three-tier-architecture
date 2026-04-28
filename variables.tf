variable "aws_region" {
    default = "ap-southeast-1"
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

variable "db_password" {
    description = "RDS master password"
    type = string
    sensitive = true
}