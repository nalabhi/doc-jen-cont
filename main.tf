provider "aws" {
#    access_key = "${var.aws_access_key}"
#    secret_key = "${var.aws_secret_key}"
     region     = "${var.region}"
}

# Create VPC #

resource "aws_vpc" "test-vpc" {
  cidr_block = var.cidr

  tags = {
    Name = "test-vpc"
  }
}

# Create Web Public Subnet
resource "aws_subnet" "app-sub" {
  vpc_id                  = aws_vpc.test-vpc.id
  cidr_block              = var.app-sub
  availability_zone       = var.zone1
  map_public_ip_on_launch = true

  tags = {
    Name = "App subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "test-igw" {
  vpc_id = aws_vpc.test-vpc.id
  tags = {
    Name = "Test IGW"
  }
}

# Route Table Routes #

resource "aws_route_table" "route_table_test" {
 vpc_id = aws_vpc.test-vpc.id
  tags = {
      Name = "Public-RT"
  }
}
resource "aws_route" "public_test" {
  route_table_id = aws_route_table.route_table_test.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.test-igw.id
}
resource "aws_route_table_association" "public_test" {
  subnet_id = aws_subnet.app-sub.id
  route_table_id = aws_route_table.route_table_test.id
}

# Create Security Group for Public Web Subnet #

resource "aws_security_group" "app_jen_secgrp" {
  name        = "allow_jen"
  description = "Allow inbound 22,80,8080"
  vpc_id      = aws_vpc.test-vpc.id

  ingress {
    description      = "Jenkins"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Public Sub Secgrp"
  }
}

#app-key 
resource "tls_private_key" "app_p_key" {
  algorithm = "RSA"
}
resource "aws_key_pair" "app-key" {
  key_name   = "app-key"
  public_key = tls_private_key.app_p_key.public_key_openssh
}
resource "local_file" "app_key_sonar" {
  depends_on = [
    tls_private_key.app_p_key,
  ]
  content  = tls_private_key.app_p_key.private_key_pem
  filename = "app_key.pem"
}
output "private_key_app" {
  description = "ssh key generated by terraform"
  value       = tls_private_key.app_p_key.private_key_pem
  sensitive   = true
}

## Creation of spot instance 

resource "aws_spot_instance_request" "app_server" {
    ami = var.ami_id
    spot_price = "0.3"
    instance_type = var.instance_type
    subnet_id = "${aws_subnet.app-sub.id}"
    associate_public_ip_address = "true"
    key_name = "app-key"
    vpc_security_group_ids = [aws_security_group.app_jen_secgrp.id]
    
  user_data = <<-EOF
      #!/bin/bash 
      yum install git -y
      yum install httpd -y
      yum install yum-utils -y
      yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
      yum install docker-ce docker-ce-cli containerd.io -y
      systemctl start docker
      lsblk
      file -s /dev/sdf
      mkfs -t xfs /dev/sdf
      mkdir jen-container 
      mount /dev/sdf /jen-container
      mkdir jenkins_image
      cd jenkins_image
      touch Dockerfile
      echo "FROM jenkins/jenkins:latest" >> Dockerfile
      echo "ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false" >> Dockerfile
      docker build -t jenkins:latest .
      docker run -d -p 8080:8080 -v /opt:/var/jenkins_home -u root jenkins:latest
      EOF
}

