variable "region" {
  type = string
  default = "eu-central-1" 
}

variable "image_tag" {
  type = string
  default = "4"
}

variable "oidc_provider" {
  description = "OIDC Provider URL for the EKS Cluster"
  type = string
  default = "oidc.eks.eu-central-1.amazonaws.com/id/6632F40BB403FEA6089A6443FFBE1101"
}



variable "service_account" {
  description = "Kubernetes Service Account Name"
  type = string
  default = "secret-accessor"
}


variable "db_password" {
  description = "password for db"
  type = string
  default = " "
}