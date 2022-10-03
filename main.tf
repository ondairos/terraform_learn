#configure remote backend tfstate to s3bucket 
terraform {
    required_version = ">= 0.12"
    backend "s3" {
        bucket = "myapp-bucket-johnk"
        key = "myapp/state.tfstate"
        region = "eu-central-1"
    }
}

provider "aws" {
    region = "eu-central-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = var.vpc_cidr_block

  azs             = [var.avail_zone]
  public_subnets  = [var.subnet_cidr_block]
  public_subnet_tags = { Name = "${var.env_prefix}-subnet-1" }

  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}


module "myapp-server" {
    source ="./modules/webserver"
    vpc_id = module.vpc.vpc_id
    my_ip = var.my_ip
    env_prefix = var.env_prefix
    image_name = var.image_name
    my_public_key = var.my_public_key
    instance_type =  var.instance_type
    subnet_id = module.vpc.public_subnets[0] #get first element of subnets array
    avail_zone = var.avail_zone
}

