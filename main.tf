provider "aws" {
    region = "eu-central-1"
}

variable "subnet_cidr_block"{
    description = "subnet cidr block"
    default = "10.0.10.0/24" #if you can't provide-find tfvars 
    type = string
}

variable "vpc_cidr_block"{
    description = "vpc cidr block"

}


resource "aws_vpc" "development-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name : "development"
        }
}

resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.development-vpc.id
    cidr_block = var.subnet_cidr_block
    #availability_zone ="eu-central-1a"
     tags = {
        Name : "subnet-1-dev"
    }
}


output "dev-vpc-id" {
    value = aws_vpc.development-vpc.id
}

output "dev-subnet-id" {
    value = aws_subnet.dev-subnet-1.id
}