# -----------------------------
# VPC
# -----------------------------
#resource "aws_vpc" "main" {
#  cidr_block = "10.0.0.0/16"

#  tags = {
#    Name = "k8s-vpc"
#  }
#}

# -----------------------------
# PUBLIC SUBNET
# -----------------------------
#resource "aws_subnet" "public" {
#  vpc_id                  = aws_vpc.main.id
#  cidr_block              = "10.0.1.0/24"
#  availability_zone       = "ap-south-1a"
#  map_public_ip_on_launch = true

#  tags = {
#    Name = "public-subnet"
#  }
#}

# -----------------------------
# INTERNET GATEWAY
# -----------------------------
#resource "aws_internet_gateway" "igw" {
#  vpc_id = aws_vpc.main.id

#  tags = {
#    Name = "k8s-igw"
#  }
#}

# -----------------------------
# ROUTE TABLE
# -----------------------------
#resource "aws_route_table" "public_rt" {
#  vpc_id = aws_vpc.main.id

#  tags = {
#    Name = "public-rt"
#  }
#}

# Route to internet
#resource "aws_route" "internet_access" {
#  route_table_id         = aws_route_table.public_rt.id
#  destination_cidr_block = "0.0.0.0/0"
#  gateway_id             = aws_internet_gateway.igw.id
#}

# Associate subnet
#resource "aws_route_table_association" "public_assoc" {
#  subnet_id      = aws_subnet.public.id
#  route_table_id = aws_route_table.public_rt.id
#}

# -----------------------------
# SECURITY GROUP
# -----------------------------
#resource "aws_security_group" "k8s_sg" {
#  name        = "k8s-sg"
#  description = "Allow k8s traffic"
#  vpc_id      = aws_vpc.main.id

#  ingress {
#    description = "SSH"
#    from_port   = 22
#    to_port     = 22
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }

#  ingress {
#    description = "Kubernetes API"
#    from_port   = 6443
#    to_port     = 6443
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }

#  ingress {
#    description = "HTTP"
#    from_port   = 80
#    to_port     = 80
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }

#  ingress {
#    description = "HTTPS"
#    from_port   = 443
#    to_port     = 443
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }

#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#}


#resource "aws_instance" "master" {
#  ami                    = "ami-05d2d839d4f73aafb"
#  instance_type          = "t3.small"
#  key_name               = "sohail"
#  subnet_id              = aws_subnet.public.id
#  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

#  user_data = file("../scripts/master.sh")

#  tags = {
#    Name = "k8s-master"
#  }
#}

#resource "aws_instance" "worker" {
#  count                  = 2
#  ami                    = "ami-05d2d839d4f73aafb"
#  instance_type          = "t3.small"
#  key_name               = "sohail"
#  subnet_id              = aws_subnet.public.id
#  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

#  user_data = file("../scripts/worker.sh")

#  tags = {
#    Name = "k8s-worker-${count.index}"
#  }
#}
