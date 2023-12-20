provider "aws" {
  region  = "eu-west-1"
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true   # Aktivera DNS-support, oklart om det behövs
  enable_dns_hostnames = true # se ovan


  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"  # Ange din önskade tillgänglighetszon
  map_public_ip_on_launch = true


  tags = {
    Name = "my-subnet"
  }
}

resource "aws_network_interface" "appserver_nic" {
  subnet_id   = aws_subnet.my_subnet.id
  security_groups = [aws_security_group.allow_me.id]


  tags = {
    Name = "appserver-nic"
  }
}

resource "aws_network_interface" "webserver_nic" {
  subnet_id   = aws_subnet.my_subnet.id
  security_groups = [aws_security_group.allow_me.id]


  tags = {
    Name = "webserver-nic"
  }
}
resource "aws_internet_gateway" "my_gw" {
  vpc_id = aws_vpc.my_vpc.id


  tags = {
    Name = "my-gw"
  }
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gw.id
  }


  tags = {
    Name = "my-route-table"
  }
}

resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_instance" "appserver" {
  ami           = "ami-0694d931cee176e7d"
  instance_type = "t2.micro"
  key_name      = "ms-key"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.appserver_nic.id
  }

  tags = {
    Name = "app-server"
  }
}

resource "aws_instance" "webserver" {
  ami           = "ami-0694d931cee176e7d"
  instance_type = "t2.micro"
  key_name      = "ms-key"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.webserver_nic.id
  }

  tags = {
    Name = "web-server"
  }
}
# Glöm inte öppna port 5000 för Docker                     OBS! Kom ihåg!
resource "aws_security_group" "allow_me" {
  name        = "allow_me"
  description = "Allow all inbound traffic"
  vpc_id = aws_vpc.my_vpc.id

   ingress {
     description = "SSH"
     from_port   = 22
     to_port     = 22
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }

   ingress  {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
   }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
    tags = {
    Name = "allow_me"
  }
}

resource "aws_eip" "eip-appserv" {
  instance = aws_instance.appserver.id
}

resource "aws_eip" "eip-webserv" {
  instance = aws_instance.webserver.id
}

output "appserver_ip" {
  value       = aws_eip.eip-appserv.public_ip
  description = "The public IP of the app server"
}

output "webserver_ip" {
  value       = aws_eip.eip-webserv.public_ip
  description = "The public IP of the web server"
}
