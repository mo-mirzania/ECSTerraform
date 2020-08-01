### AWS availability-zones data source
data "aws_availability_zones" "available_zones" {
  state                   = "available"
}

### VPC for ECS
resource "aws_vpc" "mohi_vpc" {
  cidr_block              = var.vpc_cidr
  enable_dns_hostnames    = true
  enable_dns_support      = true
  tags = {
    Name                  = "mohi_VPC"
  }
}

### Public subnets (3 for HA)
resource "aws_subnet" "mohi_public" {
  count                   = 3
  cidr_block              = cidrsubnet(aws_vpc.mohi_vpc.cidr_block, 8, count.index)
  vpc_id                  = aws_vpc.mohi_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  tags = {
    Name                  = "mohi_public_subnet_${count.index + 1}"
  }
}

### Private subnets (3 for HA)
resource "aws_subnet" "mohi_private" {
  count                   = 3
  cidr_block              = cidrsubnet(aws_vpc.mohi_vpc.cidr_block, 8, 3 + count.index)
  vpc_id                  = aws_vpc.mohi_vpc.id
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  tags = {
    Name                  = "mohi_private_subnet_${count.index + 1}"
  }
}

### Internet Gateway for the public subnets
resource "aws_internet_gateway" "mohi_igw" {
  vpc_id                  = aws_vpc.mohi_vpc.id
  tags = {
    Name                  = "mohi_igw"
  }
}

### Routing public subnets traffic through the igw
resource "aws_route" "mohi_internet_route" {
  route_table_id          = aws_vpc.mohi_vpc.main_route_table_id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.mohi_igw.id
}

### Elastic IP address for nat_gw
resource "aws_eip" "EIP_for_nat_gw" {
  vpc                     = true
  tags = {
    Name                  = "mohi_EIP"
  }
}

### NAT Gateway for private subnets
resource "aws_nat_gateway" "mohi_nat_gw" {
  allocation_id           = aws_eip.EIP_for_nat_gw.id
  subnet_id               = aws_subnet.mohi_public.0.id
}

### Route table for private subnets
resource "aws_route_table" "mohi_private_rt" {
  vpc_id                  = aws_vpc.mohi_vpc.id
  route {
    cidr_block            = "0.0.0.0/0"
    nat_gateway_id        = aws_nat_gateway.mohi_nat_gw.id
  }
  tags = {
    Name                  = "mohi_private_rt"
  }
}

### Associating private subnets to private route table
resource "aws_route_table_association" "mohi_private_rt_assoc" {
  route_table_id          = aws_route_table.mohi_private_rt.id
  count                   = 3
  subnet_id               = aws_subnet.mohi_private.*.id[count.index]
}

### Security group for ALB
resource "aws_security_group" "mohi_alb_sg" {
  name                    = "mohi-alb-sg"
  description             = "Security Group for mohi ALB"
  vpc_id                  = aws_vpc.mohi_vpc.id
  ingress {
    from_port             = 80
    protocol              = "tcp"
    to_port               = 80
    cidr_blocks           = ["0.0.0.0/0"]
  }
  egress {
    from_port             = 0
    protocol              = "-1"
    to_port               = 0
    cidr_blocks           = ["0.0.0.0/0"]
  }
}

### Security group for app
resource "aws_security_group" "mohi_ecs" {
  name                    = "mohi-ecs-sg"
  description             = "Security Group for mohi ECS"
  vpc_id                  = aws_vpc.mohi_vpc.id
  ingress {
    from_port             = 8080
    protocol              = "tcp"
    to_port               = 8080
    security_groups       = [aws_security_group.mohi_alb_sg.id]
  }
  egress {
    from_port             = 0
    protocol              = "-1"
    to_port               = 0
    cidr_blocks           = ["0.0.0.0/0"]
  }
}

### Security group for Postgres
resource "aws_security_group" "mohi_postgres" {
  name                    = "mohi-postgres-sg"
  description             = "Security Group for mohi ECS Postgres"
  vpc_id                  = aws_vpc.mohi_vpc.id
  ingress {
    from_port             = 5432
    protocol              = "tcp"
    to_port               = 5432
    cidr_blocks           = [aws_vpc.mohi_vpc.cidr_block]
  }
  egress {
    from_port             = 0
    protocol              = "-1"
    to_port               = 0
    cidr_blocks           = ["0.0.0.0/0"]
  }
}

### ALB
resource "aws_alb" "mohi_alb" {
  name                    = "mohi-alb"
  subnets                 = aws_subnet.mohi_public.*.id
  security_groups         = [aws_security_group.mohi_alb_sg.id]
}

### App target group
resource "aws_alb_target_group" "mohi_alb_tg" {
  name                    = "mohi-sys-tg"
  port                    = "8080"
  protocol                = "HTTP"
  vpc_id                  = aws_vpc.mohi_vpc.id
  target_type             = "ip"
  health_check {
    healthy_threshold     = "3"
    interval              = "30"
    protocol              = "HTTP"
    matcher               = "200"
    timeout               = "5"
    path                  = "/actuator/health"
    unhealthy_threshold   = "3"
  }
}

### Forwarding from ALB to TG
resource "aws_alb_listener" "mohi_sys_front" {
  load_balancer_arn       = aws_alb.mohi_alb.id
  port                    = 80
  default_action {
    target_group_arn      = aws_alb_target_group.mohi_alb_tg.id
    type                  = "forward"
  }
}


























