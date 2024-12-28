variable "region" {
  type = string
  default = "eu-central-1" 
}

variable "image_tag" {
  type = string
  default = "4"
}


variable "db_password" {
  description = "password for db"
  type = string
  default = " "
}