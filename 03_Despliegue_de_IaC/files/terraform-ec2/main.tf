provider "aws" {
  region = "eu-central-1"
}

resource "aws_key_pair" "example" {
  key_name   = "example-key"
  public_key = file("~/.ssh/alexjust_key.pub")
}

resource "aws_security_group" "allow_ssh_http" {
  name_prefix = "allow_ssh_http"
  vpc_id      = "vpc-0dcbbca477c748c31"  # Especifica el ID de la VPC

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0f3d898ae42d775a6"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  subnet_id     = "subnet-0b304df8b3d7ffc22"  # Especifica el ID de la subred

  tags = {
    Name = "Terraform-EC2-Web-${count.index}"
  }
}

output "instance_ips" {
  value = aws_instance.web[*].public_ip
}

