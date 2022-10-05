locals {
  ami_id = "ami-09e67e426f25ce0d7"
  vpc_id = aws_default_vpc.defaultvpc.id
  ssh_user = "ubuntu"
  key_name = "demo"
  private_key_path = "${path.cwd}/demo.pem"
}

provider "aws" {
  region     = "us-east-1"
}


resource "aws_default_vpc" "defaultvpc" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "demoaccess" {
	name   = "demoaccess"
	vpc_id = local.vpc_id

  ingress {
		from_port   = 22
		to_port     = 22
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
  ingress {
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
  ami = local.ami_id
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  vpc_security_group_ids =[aws_security_group.demoaccess.id]
  key_name = local.key_name

  tags = {
    Name = "Wordpress ec2"
  }

  connection {
    type = "ssh"
    host = self.public_ip
    user = local.ssh_user
    private_key = file(local.private_key_path)
    timeout = "4m"
  }

  provisioner "remote-exec" {
    inline = [
      "hostname"
    ]
   }
 
  provisioner "local-exec" {
  command =  "echo '[defaults]\nhost_key_checking=False' | sudo tee /etc/ansible/ansible.cfg"
 }



  provisioner "local-exec" {
    command = "echo ${self.public_ip} > myhosts"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} main.yml"
  }

}

