#config default security group
resource "aws_security_group" "myapp-sg" {
    vpc_id = var.vpc_id
    name = "myapp-sg"
    
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
        values = [var.image_name]	
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

    subnet_id = var.subnet_id
    
    vpc_security_group_ids = [aws_security_group.myapp-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    user_data = file("entry-script.sh")

    tags = {
        Name: "${var.env_prefix}-main-server"

    }

}