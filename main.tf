provider "aws" {
    region = "eu-central-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}


resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name : "${var.env_prefix}-vpc"
        }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
     tags = {
        Name : "${var.env_prefix}-subnet-1"
    }
}

#create resources for vpc route table, that enables it to connect to the internet

#create internet gateway
resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id

    tags = {
        Name: "${var.env_prefix}-igw"
    }    

}

#configure main route table
resource "aws_default_route_table" "main-rtb" {
    
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
   
   route {
        #handle the internet gateway
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    
        tags = {
            Name: "${var.env_prefix}-main-rtb"
        }

}

#config default security group
resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id 
    
    #incoming traffic rules
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]  #cidr_blocks because it's a list [using block's']
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #outcoming traffic rules
    egress {
        from_port = 0
        to_port = 0 #any ip address
        protocol = "-1" #any protocol
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
}
    tags = {
            Name: "${var.env_prefix}-default-sg"
        }

}
