provider "aws" {
  region = "eu-west-1"
  access_key = ""
  secret_key = ""
}

resource "aws_instance" "web_servers" {
  count         = 20
  ami           = "ami-0694d931cee176e7d"
  instance_type = "t2.micro"
  key_name      = "ms-key"

    tags = {
        Name = "web-server-${count.index + 1}"
    }
}

output "server_ips" {
  value = aws_instance.web_servers[*].public_ip
}
