# conta shared 
provider "aws" {
  default_tags {
    tags = local.default_tags
  }
  region = "us-east-1"

}
