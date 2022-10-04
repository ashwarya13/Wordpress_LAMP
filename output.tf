output "instance_ip" {
  value = aws_instance.web.public_ip

}

output "instance_dns" {
 value = aws_instance.web.public_dns
}
