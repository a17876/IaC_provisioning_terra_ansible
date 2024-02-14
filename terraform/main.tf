terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"

    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
  # profile = "aws_cli1"
}

# variable for vpc cidr block
variable "base_cidr_block" {
  description = "default cidr block"
  default = "192.168.0.0/16"
}

# variable for home cdir block 
variable "home_cidr_block" {
  description = "home cidr block"
  default = "207.216.90.233/32"
}

# variable for bcit cdir block 
variable "bcit_cidr_block" {
  description = "bcit cidr block"
  default = "142.232.0.0/16"
}

# variable for private subnet cidr block
variable "sub_priv_cidr_block" {
  description = "private subnet cidr block"
  default = "192.168.1.0/24"
}

# variable for public subnet cidr block
variable "sub_pub_cidr_block" {
  description = "public subnet cidr block"
  default = "192.168.2.0/24"
}

# variable for path of the public key
variable "pub_key_path" {
  description = "path of the public key"
  default = "/home/kaylyn/.ssh/terra.pub"
}


# get the most recent ami for Ubuntu 23.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-lunar-23.04-amd64-server-*"]
  }
}

# Create a VPC
resource "aws_vpc" "a02_vpc" {
  cidr_block           = var.base_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "a02_vpc"
  }
}

# Create a private subnet
resource "aws_subnet" "a02_priv_subnet" {
  vpc_id                  = aws_vpc.a02_vpc.id
  cidr_block              = var.sub_priv_cidr_block
  availability_zone            = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "a02_priv_subnet"
  }
}

# Create a public subnet
resource "aws_subnet" "a02_pub_subnet" {
  vpc_id                  = aws_vpc.a02_vpc.id
  cidr_block              = var.sub_pub_cidr_block
  availability_zone            = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "a02_pub_subnet"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "a02_gw" {
  vpc_id = aws_vpc.a02_vpc.id

  tags = {
    Name = "a02_gw"
  }
}

# Create a route table
resource "aws_route_table" "a02_route" {
  vpc_id = aws_vpc.a02_vpc.id
  
  tags = {
    Name = "a02_route"
  }
}

# add route to route table
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.a02_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.a02_gw.id
}

# associate the route table with private subnet
resource "aws_route_table_association" "a02_priv" {
  subnet_id      = aws_subnet.a02_priv_subnet.id
  route_table_id = aws_route_table.a02_route.id
}

# associate the route table with public subnet
resource "aws_route_table_association" "a02_pub" {
  subnet_id      = aws_subnet.a02_pub_subnet.id
  route_table_id = aws_route_table.a02_route.id
}

# Security group for backend(private) ec2 instance
resource "aws_security_group" "a02_priv_sg" {
  name        = "allow-ssh"
  description = "allow ssh from home and work"
  vpc_id      = aws_vpc.a02_vpc.id

  tags = {
    Name = "a02_priv_sg"
  }
} 

# Security group for web(public) ec2 instance
resource "aws_security_group" "a02_pub_sg" {
  name        = "allow-ssh-http"
  description = "allow ssh from home and work / http from anywhere"
  vpc_id      = aws_vpc.a02_vpc.id

  tags = {
    Name = "a02_pub_sg"
  }
}

## Ingress rules for backend(private) ec2 instance security group
# allow ssh from home
resource "aws_vpc_security_group_ingress_rule" "a02_priv_ssh_home" {
  security_group_id = aws_security_group.a02_priv_sg.id

  cidr_ipv4   = var.home_cidr_block
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

# allow ssh from bcit
resource "aws_vpc_security_group_ingress_rule" "a02_priv_ssh_bcit" {
  security_group_id = aws_security_group.a02_priv_sg.id

  cidr_ipv4   = var.bcit_cidr_block
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

# # allow all traffic from a02_pub_sg security group
resource "aws_vpc_security_group_ingress_rule" "all_pub" {
  security_group_id = aws_security_group.a02_priv_sg.id

  cidr_ipv4   = var.sub_pub_cidr_block
  ip_protocol = -1

}

## Ingress rules for web(public) ec2 instance security group
# allow all traffic dest port 80 from anywhere
resource "aws_vpc_security_group_ingress_rule" "a02_pub_http" {
  security_group_id = aws_security_group.a02_pub_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

# allow all traffic dest port 443 from anywhere
resource "aws_vpc_security_group_ingress_rule" "a02_pub_https" {
  security_group_id = aws_security_group.a02_pub_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}

# allow ssh from home
resource "aws_vpc_security_group_ingress_rule" "a02_pub_ssh_home" {
  security_group_id = aws_security_group.a02_pub_sg.id

  cidr_ipv4   =  var.home_cidr_block
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

# allow ssh from bcit
resource "aws_vpc_security_group_ingress_rule" "a02_pub_ssh_bcit" {
  security_group_id = aws_security_group.a02_pub_sg.id

  cidr_ipv4   =  var.bcit_cidr_block
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

## Egress rule for backend(private) ec2 instance security group
# any destination and protocol
resource "aws_vpc_security_group_egress_rule" "a02_priv_egress" {
  security_group_id = aws_security_group.a02_priv_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

## Egress rule for web(public) ec2 instance security group
# any destination and protocol
resource "aws_vpc_security_group_egress_rule" "a02_pub_egress" {
  security_group_id = aws_security_group.a02_pub_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

# use an existing key pair on host machine with file func
resource "aws_key_pair" "local_key" {
  key_name = "terra"
  public_key = file(var.pub_key_path)
}

## Create EC2 instance that uses the latest ubuntu ami from data the local key above
# Create a02_backend_ec2 instance
resource "aws_instance" "a02_backend_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.local_key.id
  vpc_security_group_ids = [aws_security_group.a02_priv_sg.id]
  subnet_id              = aws_subnet.a02_priv_subnet.id

  tags = {
    Name = "a02_backend_instance"
  }
}

# Create a02_db_ec2 instance
resource "aws_instance" "a02_db_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.local_key.id
  vpc_security_group_ids = [aws_security_group.a02_priv_sg.id]
  subnet_id              = aws_subnet.a02_priv_subnet.id

  tags = {
    Name = "a02_db_instance"
  }
}

# Create a02_web_ec2 instance
resource "aws_instance" "a02_web_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.local_key.id
  vpc_security_group_ids = [aws_security_group.a02_pub_sg.id]
  subnet_id              = aws_subnet.a02_pub_subnet.id

  tags = {
    Name = "a02_web_instance"
  }
}

# write data to file when resources are created
# file will be managed with terraform, deleted with resources are destroyed
resource "local_file" "vpc_vars_file" {
  content       = <<-eof
    tf_vpc_id: ${aws_vpc.a02_vpc.id}
    tf_ec2_backend_dns: ${aws_instance.a02_backend_ec2.public_dns}
    tf_ec2_db_dns: ${aws_instance.a02_db_ec2.public_dns}
    tf_ec2_web_dns: ${aws_instance.a02_web_ec2.public_dns}
  eof
  file_permission = "0640"
  filename         = "vpc_vard.yaml"
}

# print out to screen when resources are created
# also when command "terraform output" is run
output "instance_ip_addr" {
  value       = aws_instance.a02_web_ec2.public_ip
  description = "The public IP address of the ec2 instance."
}

