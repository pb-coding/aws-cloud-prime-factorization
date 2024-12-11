variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "my_ip" {
  type    = string
}

variable "aws_instance_type" {
  type = string
}

variable "number_of_workers" {
  type = number
}

variable "number_of_slaves" {
  type = number
}

variable "number_of_threads" {
  type = number
}

variable "number_to_factor" {
  type = number
}