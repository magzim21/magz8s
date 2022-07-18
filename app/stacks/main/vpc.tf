module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "eks-${var.tags.project}"
  cidr = var.vpc_cidr

  azs             = ["${data.aws_region.current.id}a", "${data.aws_region.current.id}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.100.0/24", "10.0.101.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true


# These tags are required to enable autodiscovery. Many kubernetes operators use autodiscovery by these tags.
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.tags.project}" = "shared"
    "kubernetes.io/role/elb"                        = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.tags.project}" = "shared"
    "kubernetes.io/role/internal-elb"               = 1
  }

  # tags = var.tags
}