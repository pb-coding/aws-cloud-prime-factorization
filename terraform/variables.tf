variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "my_ip" {
  type    = string
}

variable "number_to_factor" {
  type = number
}