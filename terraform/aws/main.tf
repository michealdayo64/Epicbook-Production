#-------------------------
# Create a VPC
#---------------------------
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "epicbook-vpc"
  }
}

# ---------------------------
# Availability Zone lookup
# ---------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

#-------------------------------------------------
# Subnets Definition
#------------------------------------------------
resource "aws_subnet" "public_subnet" {

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "public-subnet-1"
  }

}

resource "aws_subnet" "private_subnet_db_1" {

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_db_cidrs[0]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "private-db-subnet-a"
  }

}

resource "aws_subnet" "private_subnet_db_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_db_cidrs[1]
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "private-db-subnet-b"
  }
}

#-----------------------------------------------
# Internet Gateway
#-----------------------------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "epicbook-internet-gateway"
  }
}

#-------------------------------------------------
# Route Tables
#-------------------------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = var.ipv4_anywhere
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "epicbook-public-route-table"
  }

}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "epicbook-private-route-table"
  }
}

#----------------------------------------------------------------------
# Route Tables Association
#----------------------------------------------------------------------
resource "aws_route_table_association" "rt_association_public_1" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "rt_association_private_1" {
  subnet_id      = aws_subnet.private_subnet_db_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "rt_association_private_2" {
  subnet_id      = aws_subnet.private_subnet_db_2.id
  route_table_id = aws_route_table.private_rt.id
}

#----------------------------------------------------------------
# Security Groups
#----------------------------------------------------------------
resource "aws_security_group" "vm_sg" {
  name        = var.vm-security-group-name
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.vpc.id

  # Allow SSH from your IP address
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["102.88.108.149/32"]
  }

  # Allow HTTP from anywhere
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.ipv4_anywhere]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "epicbook-vm-sg"
  }

}

resource "aws_security_group" "db_sg" {
  name        = var.db-security-group-name
  description = "Security group for rds database"
  vpc_id      = aws_vpc.vpc.id

  # Allow mysql from your ec2 security group
  ingress {
    description     = "mysql"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.vm_sg.id]
  }


  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "epicbook-db-sg"
  }

}


data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


# Create EC2 Key Pair
resource "aws_key_pair" "deployer1" {
  key_name   = var.key_name_vm
  public_key = file(var.vm_public_key)

  tags = {
    Name = "${var.project_name}-key"
  }
}

# Create EC2 Instance
resource "aws_instance" "epicbook_vm" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.public_subnet.id

  vpc_security_group_ids = [
    aws_security_group.vm_sg.id
  ]

  key_name = aws_key_pair.deployer1.key_name

  associate_public_ip_address = true


  tags = {
    Name = "${var.project_name}-ec2-web"
  }
}

resource "aws_db_subnet_group" "epicbook_subnet_group" {
  #count       = length(var.private_subnet_db_cidrs)
  name        = "${var.project_name}-db-subnet-group"
  description = "DB subnet group for EpicBook RDS"

  subnet_ids = [
    aws_subnet.private_subnet_db_1.id,
    aws_subnet.private_subnet_db_2.id
  ]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "book_review_db" {
  identifier = "${var.project_name}-mysql"

  # Database engine
  engine = "mysql"

  # Small instance suitable for the lab
  instance_class = var.db_instance_class

  # Database storage
  allocated_storage = 20
  storage_type      = "gp2"

  storage_encrypted = true

  # Database credentials
  username = var.db_username
  password = var.db_password

  # Database networking
  db_subnet_group_name   = aws_db_subnet_group.epicbook_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  # Keep database private
  publicly_accessible = false

  backup_retention_period = 7

  backup_window = "03:00-04:00"

  maintenance_window = "sun:04:00-sun:05:00"

  # Lab-friendly settings
  multi_az            = false
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-mysql"
  }
}

