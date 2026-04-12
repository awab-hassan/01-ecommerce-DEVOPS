provider "aws" {
  region = "ap-south-1"
}

terraform {
  required_version = ">=0.12"
}

data "aws_availability_zones" "azs" {}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  repository_name = "java-ecom"

  repository_image_scan_on_push = true

  repository_encryption_type = "AES256"

  repository_force_delete = true

  tags = {
    Name = "java-ecom"
  }
}

module "my_vpc"{
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"
  name = "my-vpc"
  cidr = "10.0.0.0/16"
  public_subnets = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
  private_subnets = ["10.0.4.0/24","10.0.5.0/24","10.0.6.0/24"]
  azs = data.aws_availability_zones.azs.names
  enable_nat_gateway = true
  enable_dns_hostnames = true
  single_nat_gateway = true
  tags = {
    "kubernetes.io/cluster/eks_cluster" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/eks_cluster" = "shared"
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/eks_cluster" = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.30.2"
  cluster_name = "eks_cluster"
  cluster_version = "1.23"
  subnet_ids = module.my_vpc.private_subnets
  vpc_id = module.my_vpc.vpc_id
  tags = {
    environment = "dev"
    application = "java-app"
  }
  eks_managed_node_groups = {
    dev = {
      min_size = 2
      max_size = 4
      desired_size = 3
      instance_type = ["m5.large"]
    }
  }
}
