locals {
  ami_id = "ami-09e67e426f25ce0d7"
  vpc_id = aws_default_vpc.defaultvpc.id
  ssh_user = "ubuntu"
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

resource "aws_key_pair" "demo" {

  key_name = "demo"

  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDA1gPO1evCLPHn4hGTeyK5qrDJNRWsMOoGyfPO26x5Wwcr5ye1vcfWEFeNJAnYpoAK6lo2ygOEqX0AHlFho+XPjp1ZwCLemA+P+w4h5X3bmzmSZW8eyyT6jHy7SzXoANE3KUL4IWK9ojcyMVuuxW0c6o9mia9Y5TFYqxZ9ZWQuAzGa9R9A5NXNYZpiausJeODIOtBmY6o69DSovE3VbFznvS99QWoJuWyF2Lp7mq/nwFqwSroYxh/lmYhz/XQ5BXFu8wibTkvK0/eDUp2/vysUnzMmImJALbJoe1UcZd3SCCiJUyh3TUMmn7LaXj6qWAZqTXgUywBeZJqxGeKITnUzhSIkXaQvLsnnQTkiMiR8dcNR1Os0g2gW+bMxjE3094F1aVYGzNGQ8+9fkPWMrnpLmBFB0N5jrgiKL4lCjFrs7BwxlqScPM05U7rUL4iN+pluzhKcYu3x9UhaFLmyQCE1Oi2t/t/uMYFH1nGjecmynm2dh7SaZ499V5w57ruKEwU= labsuser@ip-172-31-56-96"

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
  key_name = aws_key_pair.demo.key_name

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
  command =  "sudo chmod 400 demo.pem"
 }


  provisioner "local-exec" {
    command = "echo ${self.public_ip} > myhosts"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} main.yml"
  }

}

