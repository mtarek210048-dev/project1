# ──────────────────────────────────────────
# VPC
# ──────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ──────────────────────────────────────────
# Internet Gateway
# ──────────────────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-${var.environment}-igw"
    Project = var.project_name
  }
}

# ──────────────────────────────────────────
# Public Subnets
# ──────────────────────────────────────────
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Tier    = "public"
    Project = var.project_name
  }
}

# ──────────────────────────────────────────
# Private Subnets
# ──────────────────────────────────────────
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name    = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Tier    = "private"
    Project = var.project_name
  }
}

# ──────────────────────────────────────────
# Elastic IP + NAT Gateway (in first public subnet)
# ──────────────────────────────────────────
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name    = "${var.project_name}-${var.environment}-nat-eip"
    Project = var.project_name
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name    = "${var.project_name}-${var.environment}-nat"
    Project = var.project_name
  }

  depends_on = [aws_internet_gateway.main]
}

# ──────────────────────────────────────────
# Route Tables
# ──────────────────────────────────────────

# Public route table — routes all traffic to IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private route table — routes outbound traffic through NAT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-private-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
