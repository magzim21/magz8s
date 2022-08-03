module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "eks-${var.tags.project}-${var.tags.environment}"
  cidr = var.vpc_cidr

  azs             = ["${data.aws_region.current.id}a", "${data.aws_region.current.id}b"]
  private_subnets = [cidrsubnet(var.vpc_cidr, 6, 0), cidrsubnet(var.vpc_cidr, 6, 1)]
  public_subnets  = [cidrsubnet(var.vpc_cidr, 6, 2),cidrsubnet(var.vpc_cidr, 6, 3)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true


# These tags are required to enable autodiscovery. Many kubernetes operators use autodiscovery by these tags.
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.tags.project}-${var.tags.environment}" = "shared"
    "kubernetes.io/role/elb"                        = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.tags.project}-${var.tags.environment}" = "shared"
    "kubernetes.io/role/internal-elb"               = 1
  }

  # tags = var.tags
  depends_on = [
    null_resource.sleep_vpc
  ]
}


resource "null_resource" "sleep_vpc" {
  # todo: maybe remove this trigger and simplify script.
  # triggers = {
  #   always_run = "${timestamp()}"
  # }
  provisioner "local-exec" {

    command = "sleep 300"
    when = destroy
  }
}
