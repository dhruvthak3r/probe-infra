provider "aws" {
  profile = "probe"
  region = "ap-south-1"
}

data "aws_vpc" "default" {
  default = true
}



resource "aws_instance" "probe" {
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type
  key_name      = var.ssh_key
  vpc_security_group_ids = [aws_security_group.probe_sg.id]

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/ubuntu/docker-compose.yml"
  }

  provisioner "file" {
    source      = "setup.sh"
    destination = "/home/ubuntu/setup.sh"
  }

  provisioner "file" {
    source      = ".env"
    destination = "/home/ubuntu/.env"
  }

   provisioner "remote-exec" {
        inline = [
        "chmod +x /home/ubuntu/setup.sh",
        "sudo /home/ubuntu/setup.sh"
        ]
    }

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("probe-ssh.pem")
      host = self.public_ip
      timeout = "2m"
    }
  
}


resource "aws_security_group" "probe_sg" {
  name        = "probe_sg"
  description = "Security group for probe instance"
  vpc_id = data.aws_vpc.default.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }


  ingress {
    from_port = 8181
    to_port = 8181
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }

  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

}