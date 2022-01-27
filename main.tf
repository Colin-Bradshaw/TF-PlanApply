resource "aws_vpc" "utopia_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "utopia"
  }
}

resource  "aws_internet_gateway" "utopia_gateway" {
  vpc_id = aws_vpc.utopia_vpc.id
  depends_on = [aws_vpc.utopia_vpc]
}

resource "aws_nat_gateway" "utopia_nat" {
  connectivity_type = "private"
  subnet_id = aws_subnet.utopia_public_subnet.id
  
  tags = {
    Name = "Utopia_nat"
  }
  
  depends_on = [aws_internet_gateway.utopia_gateway]
}

resource "aws_db_instance" "utopia-rds" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  name                 = "utopia_db"
  username             = "foo"
  password             = "foobarbaz"
  skip_final_snapshot  = true
}

resource "aws_kms_key" "utopia_key" {
  description = "utopia kms key"
}

resource "aws_s3_bucket" "utopia-bucket" {
  bucket = "utopia-bucket"
  acl = "private"
  versioning {
    enabled = true
  }
  
  tags = {
    Name = "utopia_bucket"
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "tf-utopia-state"
  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }
  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
	
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.utopia_vpc.id
  
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.utopia_vpc.cidr_block]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "allow_ssh"
  }
  depends_on = [aws_vpc.utopia_vpc]
}

resource "aws_route_table" "utopia_route_table" {
  vpc_id = aws_vpc.utopia_vpc.id
  route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.utopia_gateway.id
  }
  tags = {
    Name = "Utopia_Route_Table"
  }
  depends_on = [aws_vpc.utopia_vpc]
}

resource "aws_subnet" "utopia_public_subnet" {
  vpc_id = aws_vpc.utopia_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  
  tags = {
    Name = "utopia public subnet"
  }
  depends_on = [aws_vpc.utopia_vpc]
}

resource "aws_subnet" "utopia_private_subnet" {
  vpc_id = aws_vpc.utopia_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2c"
  
  tags = {
    Name = "utopia private subnet"
  }
  depends_on = [aws_vpc.utopia_vpc]
}

resource "aws_main_route_table_association" "vpc_association" {
  vpc_id = aws_vpc.utopia_vpc.id
  route_table_id = aws_route_table.utopia_route_table.id
}

resource "aws_network_interface" "utopia_network_interface" {
  subnet_id = aws_subnet.utopia_public_subnet.id
  private_ips = ["10.0.1.4"]
  security_groups = [aws_security_group.allow_ssh.id]
  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_lb" "utopia_lb" {
  name = "utopia-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.allow_ssh.id]
  subnets = [aws_subnet.utopia_public_subnet.id, aws_subnet.utopia_private_subnet.id]

}



