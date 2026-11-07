resource "aws_vpc" "VPC-1" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "My-VPC"
    }
  
}

resource "aws_subnet" "pub-sub-1" {
    vpc_id = aws_vpc.VPC-1.id
    cidr_block = "10.0.1.0/24"
    tags = {
        Name = "public-subnet"
    }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.VPC-1.id

  tags = {
    Name = "IGW"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.VPC-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-RT"
  }
}

resource "aws_route_table_association" "public-rt-association" {
  subnet_id      = aws_subnet.pub-sub-1.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_instance" "pub-instance" {
    subnet_id = aws_subnet.pub-sub-1.id
    ami = "ami-0c230065b91270bc6"
    instance_type = "t3.micro"
    tags = {
        Name = "pub-server-1"
    }
}

resource "aws_subnet" "frontend-sub-1" {
    vpc_id = aws_vpc.VPC-1.id
    cidr_block = "10.0.2.0/24"
    tags = {
        Name = "private-subnet-1"
    }
}

resource "aws_subnet" "backend-sub-2" {
    vpc_id = aws_vpc.VPC-1.id
    cidr_block = "10.0.3.0/24"
    tags = {
        Name = "private-subnet-2"
    }
}

resource "aws_nat_gateway" "regional-nat" {
    vpc_id            = aws_vpc.VPC-1.id
    availability_mode = "regional"
    connectivity_type = "public"

    tags = {
        Name = "Regional-NAT-Gateway"
      }

    depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private-rt" {
    vpc_id = aws_vpc.VPC-1.id

    route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.regional-nat.id
      }

    tags = {
        Name = "Private-RT"
      }
}

resource "aws_route_table_association" "private-rt-association" {

  for_each = {
    frontend = aws_subnet.frontend-sub-1.id
    backend  = aws_subnet.backend-sub-2.id
    db-1     = aws_subnet.pvt-db-sub-1.id
    db-2     = aws_subnet.pvt-db-sub-2.id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_instance" "frontend" {
    subnet_id = aws_subnet.frontend-sub-1.id
    ami = "ami-0c230065b91270bc6"
    instance_type = "t3.micro"
    tags = {
        Name = "frontend-server"
    }

}

resource "aws_instance" "backend" {
    subnet_id = aws_subnet.backend-sub-2.id
    ami = "ami-0c230065b91270bc6"
    instance_type = "t3.micro"
    tags = {
        Name = "backend-server"
    }
}

resource "aws_subnet" "pvt-db-sub-1" {
    vpc_id = aws_vpc.VPC-1.id
    availability_zone = "us-east-1d"
    cidr_block = "10.0.4.0/24"
    tags = {
        Name = "db-subnet-1"
    }
}

resource "aws_subnet" "pvt-db-sub-2" {
    vpc_id = aws_vpc.VPC-1.id
    availability_zone = "us-east-1c"
    cidr_block = "10.0.5.0/24"
    tags = {
        Name = "db-subnet-2"
    }
}

resource "aws_db_subnet_group" "subnet-group" {
    subnet_ids = [aws_subnet.pvt-db-sub-1.id , aws_subnet.pvt-db-sub-2.id]
    tags = {
        Name = "my-subnet-group"
    }
}

resource "aws_db_instance" "rds" {
    db_subnet_group_name = aws_db_subnet_group.subnet-group.name
    allocated_storage    = 20
    identifier           = "my-db-instance"
    engine               = "mysql"
    engine_version       = "8.0"
    instance_class       = "db.t4g.micro"

    username             = "admin"
    password             = "MyStrongPassword123!"

    parameter_group_name = "default.mysql8.0"
}