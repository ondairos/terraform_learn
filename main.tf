provider "aws" {
    region = "eu-central-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
variable my_public_key {}


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

#get the most recent amazon image 
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]	
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image
}


#create ssh key pair
resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = var.my_public_key
}


#create aws instance EC2
resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    user_data = file("entry-script.sh")

    tags = {
        Name: "${var.env_prefix}-main-server"

    }

}