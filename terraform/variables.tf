locals {
  default_tags = {
    managed_by = "terraform"
    produto    = "ecs-cluster"
    ambiente   = "dev"
    tribo      = "infra"
  }


  policies_nodes = {
    "AmazonEC2ContainerServiceRole"       = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
    "AmazonEC2ContainerServiceforEC2Role" = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    "AmazonEC2RoleforSSM"                 = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
    "AmazonS3ReadOnlyAccess"              = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  }

  frontend-image-url = ""
  backend-image-url  = ""
}