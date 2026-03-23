variable "region" {
  default = "ap-south-1"
}

variable "ami" {
  default = "ami-05d2d839d4f73aafb"
}

variable "instance_type" {
  default = "m7i-flex.large"
}

variable "key_name" {
  default = "sohail"
}

variable "worker_count" {
  default = 2
}
