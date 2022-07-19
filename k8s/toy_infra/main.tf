provider "aws" {
  region = "us-east-1"
}


data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = var.vpc_name
    Environment = "jl_k8s_env"
    Terraform   = "True"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "jl_k8s_igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name      = "public_facing_route_table"
    Terraform = true
  }
}

resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public_subnets]
  route_table_id = aws_route_table.public_route_table.id
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
}


resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[each.value]
  map_public_ip_on_launch = true
  tags = {
    Name      = each.key
    Terrafrom = true
  }
}

resource "aws_iam_role" "eks_toy_role" {
  name = "public_eks_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }]
  })

}

resource "aws_iam_role_policy_attachment" "EKS-ClusterPerms" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_toy_role.name
}

resource "aws_iam_role_policy_attachment" "EKS-VPCPerms" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_toy_role.name
}

resource "aws_eks_cluster" "jl_toy_cluster" {
  name     = "public_eks_toy"
  role_arn = aws_iam_role.eks_toy_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.public_subnets["public_subnet_1"].id,aws_subnet.public_subnets["public_subnet_2"].id]
  }
}
