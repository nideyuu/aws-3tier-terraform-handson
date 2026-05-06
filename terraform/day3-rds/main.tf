provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}
# =========================
# Public Subnets
# =========================

resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-1c"
  }
}

# =========================
# Private App Subnets
# =========================

resource "aws_subnet" "private_app_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "private-app-1a"
  }
}

resource "aws_subnet" "private_app_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "private-app-1c"
  }
}

# =========================
# Private DB Subnets
# =========================

resource "aws_subnet" "private_db_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "private-db-1a"
  }
}

resource "aws_subnet" "private_db_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "private-db-1c"
  }
}
# =========================
# Internet Gateway
# =========================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-igw"
  }
}

# =========================
# Public Route Table
# =========================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route"
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}
resource "aws_eip" "nat_1a" {
  domain = "vpc"

  tags = {
    Name = "nat-eip-1a"
  }
}

resource "aws_eip" "nat_1c" {
  domain = "vpc"

  tags = {
    Name = "nat-eip-1c"
  }
}
resource "aws_nat_gateway" "nat_1a" {
  allocation_id = aws_eip.nat_1a.id
  subnet_id     = aws_subnet.public_1a.id

  tags = {
    Name = "nat-1a"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat_1c" {
  allocation_id = aws_eip.nat_1c.id
  subnet_id     = aws_subnet.public_1c.id

  tags = {
    Name = "nat-1c"
  }

  depends_on = [aws_internet_gateway.main]
}
# =========================
# Private App Route Tables
# =========================

resource "aws_route_table" "private_app_1a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1a.id
  }

  tags = {
    Name = "private-app-route-1a"
  }
}

resource "aws_route_table" "private_app_1c" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1c.id
  }

  tags = {
    Name = "private-app-route-1c"
  }
}

resource "aws_route_table_association" "private_app_1a" {
  subnet_id      = aws_subnet.private_app_1a.id
  route_table_id = aws_route_table.private_app_1a.id
}

resource "aws_route_table_association" "private_app_1c" {
  subnet_id      = aws_subnet.private_app_1c.id
  route_table_id = aws_route_table.private_app_1c.id
}
# =========================
# Private DB Route Tables
# Day1では仮でNATへ向ける
# Day3以降、DBを完全閉域にするなら0.0.0.0/0ルートを削除
# =========================

resource "aws_route_table" "private_db_1a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1a.id
  }

  tags = {
    Name = "private-db-route-1a"
  }
}

resource "aws_route_table" "private_db_1c" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1c.id
  }

  tags = {
    Name = "private-db-route-1c"
  }
}

resource "aws_route_table_association" "private_db_1a" {
  subnet_id      = aws_subnet.private_db_1a.id
  route_table_id = aws_route_table.private_db_1a.id
}

resource "aws_route_table_association" "private_db_1c" {
  subnet_id      = aws_subnet.private_db_1c.id
  route_table_id = aws_route_table.private_db_1c.id
}
resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}
resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = aws_vpc.main.id

  ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
resource "aws_instance" "app_1a" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.private_app_1a.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "Hello from 1a" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "app-1a"
  }
}
resource "aws_instance" "app_1c" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.private_app_1c.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "Hello from 1c" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "app-1c"
  }
}
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

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

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_lb" "main" {
  name               = "my-alb"
  load_balancer_type = "application"

  subnets = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1c.id
  ]

  security_groups = [aws_security_group.alb_sg.id]

  tags = {
    Name = "my-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "app_1a" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app_1a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "app_1c" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app_1c.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}
resource "aws_db_subnet_group" "main" {
  name = "db-subnet-group"

  subnet_ids = [
    aws_subnet.private_db_1a.id,
    aws_subnet.private_db_1c.id
  ]

  tags = {
    Name = "db-subnet-group"
  }
}
resource "aws_db_instance" "main" {
  identifier = "my-rds"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "appdb"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "my-rds"
  }
}
