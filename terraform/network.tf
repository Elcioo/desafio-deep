# VPC para deploy dos recursos
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = local.default_tags
}

# Sub-redes Públicas para provisionamento do load balancer exposto para internet
resource "aws_subnet" "subnet_public_one" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = local.default_tags
}

resource "aws_subnet" "subnet_public_two" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = local.default_tags
}

# Sub-redes Privadas
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags              = local.default_tags
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags              = local.default_tags
}


# Internet Gateway para utilizar nas subnets publicas
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = local.default_tags
}

# Route Table para subnets públicas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = local.default_tags
}

# Associação da Route Table com as subnets publicas para conexão com a internet 

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.subnet_public_one.id
  route_table_id = aws_route_table.public.id


}

resource "aws_route_table_association" "subnet_public_two" {
  subnet_id      = aws_subnet.subnet_public_two.id
  route_table_id = aws_route_table.public.id
}

# Elastic IP para o NAT Gateway
resource "aws_eip" "nat" {
  tags = local.default_tags
}

# NAT Gateway para conexão das subnets internas
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnet_public_one.id

  tags = local.default_tags
}

# Route table para subnets privadas
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = local.default_tags
}

# Associação da Route Table com as subnets privadas para conexão com a internet 
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

