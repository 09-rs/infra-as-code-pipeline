variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "container_port" {
  type    = number
  default = 5000
}