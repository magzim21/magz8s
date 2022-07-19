# This is where you put your outputs declaration

output "eks_vpc" {
  value = module.vpc
}

output "eks" {
  value = module.eks
}

