resource "aws_vpc" "main_vpc" {
  cidr_block = var.cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.main_vpc.id
  count = length(var.public_subnet_cidr)
  cidr_block = element(var.public_subnet_cidr, count.index)
  availability_zone = element(var.availability_zone, count.index)

  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public-subnet-${count.index + 1}"
  }
}

# Private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.main_vpc.id
  count = length(var.private_subnet_cidr)
  cidr_block = element(var.private_subnet_cidr, count.index)
  availability_zone = element(var.availability_zone, count.index)

  tags = {
    Name = "${var.vpc_name}-private-subnet-${count.index + 1}"
  }
}

# internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

#public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route" "public_internet_route" {
  route_table_id = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_rt_association" {
  count = length(var.public_subnet_cidr)
  subnet_id = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}


#private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_rt_association" {
  count = length(var.private_subnet_cidr)
  subnet_id = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}


# Network ACL Section 
resource "aws_network_acl" "vpc_acl" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${var.vpc_name}-NACL"
  }
}

resource "aws_network_acl_rule" "public_http_inbound" {
  network_acl_id = aws_network_acl.vpc_acl.id
  rule_number    = 100
  rule_action    = "allow"
  protocol       = "6"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_https_inbound" {
  network_acl_id = aws_network_acl.vpc_acl.id
  rule_number    = 110
  rule_action    = "allow"
  protocol       = "6"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_ssh_inbound" {
  network_acl_id = aws_network_acl.vpc_acl.id
  rule_number    = 120
  rule_action    = "allow"
  protocol       = "6" #TCP 
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "public_icmp_inbound" {
  network_acl_id = aws_network_acl.vpc_acl.id
  rule_number    = 90
  rule_action    = "allow"
  protocol       = "1" # ICMP
  egress         = false
  cidr_block     = "0.0.0.0/0" # Or the CIDR of the *other* VPC
  from_port      = -1
  to_port        = -1
}

resource "aws_network_acl_rule" "public_deny_all_inbound" {
  network_acl_id = aws_network_acl.vpc_acl.id
  rule_number    = 300
  rule_action    = "deny"
  protocol       = "-1"
  egress         = false
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_allow_all_outbound" {
  network_acl_id = aws_network_acl.vpc_acl.id
  rule_number    = 200
  rule_action    = "allow"
  protocol       = "-1"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}
