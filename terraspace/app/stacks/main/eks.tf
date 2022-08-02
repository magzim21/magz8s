

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.23.0"

  cluster_name    = local.eks_cluser_name
  cluster_version = "1.22"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # cluster_addons = {
  #   coredns = {
  #     resolve_conflicts = "OVERWRITE"
  #   }
  #   kube-proxy = {}
  #   vpc-cni = {
  #     resolve_conflicts = "OVERWRITE"
  #   }
  # }

  # cluster_encryption_config = [{
  #   provider_key_arn = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  #   resources        = ["secrets"]
  # }]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)

  # # Self Managed Node Group(s)
  # self_managed_node_group_defaults = {
  #   instance_type                          = "m6i.large"
  #   update_launch_template_default_version = true
  #   iam_role_additional_policies = [
  #     "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  #   ]
  # }

  # self_managed_node_groups = {
  #   one = {
  #     name         = "mixed-1"
  #     max_size     = 5
  #     desired_size = 2

  #     use_mixed_instances_policy = true
  #     mixed_instances_policy = {
  #       instances_distribution = {
  #         on_demand_base_capacity                  = 0
  #         on_demand_percentage_above_base_capacity = 10
  #         spot_allocation_strategy                 = "capacity-optimized"
  #       }

  #       override = [
  #         {
  #           instance_type     = "m5.large"
  #           weighted_capacity = "1"
  #         },
  #         {
  #           instance_type     = "m6i.large"
  #           weighted_capacity = "2"
  #         },
  #       ]
  #     }
  #   }
  # }

  # EKS Managed Node Group(s)
  # eks_managed_node_group_defaults = {
  #   disk_size      = 50
  #   instance_types = ["t3.medium"]
  # }

  eks_managed_node_groups = {
    private = {
      min_size     = 2
      max_size     = 10
      desired_size = 2

      instance_types = ["t3.medium","t3a.xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = "30"
      subnet_ids     = module.vpc.private_subnets
    }
    private_powerful = {
      min_size     = 0
      max_size     = 5
      desired_size = 0

      instance_types = ["t3a.xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = "30"
      subnet_ids     = module.vpc.private_subnets
    }
    public = {
      min_size     = 2
      max_size     = 10
      desired_size = 2

      instance_types = ["t3.medium","t3a.xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = "30"
      subnet_ids     = module.vpc.public_subnets
    }
  }

  # create_node_security_group
  # create_cluster_security_group = false
  node_security_group_additional_rules = {
    # besides well known node port range 30000-32767 kube-proxy uses arbitrary(?) ports for cluster IPs. Allowing all traffic between nodes.  
    ingress_allow_all_self = {
      description = "EKS node port default range udp"
      protocol    = "all"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    allow_pod_cidr_traffic = {
      description = "Allow pod cidr traffic. That is eks subnets"
      protocol    = "all"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = concat(module.vpc.private_subnets_cidr_blocks, module.vpc.public_subnets_cidr_blocks, ["172.20.0.0/16"])
    }
    enress_allow_all_self = {
      description = "EKS allow all all traffic inside SG"
      protocol    = "all"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      self        = true
    }
    egress_allow_all_all = {
      description = "EKS node port default range all"
      protocol    = "all"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }


  # AWS Fargate is a technology that provides on-demand, right-sized compute capacity for containers.
  fargate_profiles = {
    default = {
      name = "default"
      # About selectors https://eksctl.io/usage/fargate-support/
      selectors = [
        {
          namespace = "fargate"
        #   labels = {
        #     Application = "backend"
        #   }
        },
        {
          namespace = "serverless"
        #   labels = {
        #     WorkerType = "fargate"
        #   }
        # }
        },
        {
          namespace = "tutu"
        #   labels = {
        #     WorkerType = "fargate"
        #   }
        }
      ]

      # Using specific subnets instead of the subnets supplied for the cluster itself
      # TODO: Create a special subnet for Fargate profiles
      subnet_ids = module.vpc.private_subnets

      tags = var.tags

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    }

    secondary = {
      name = "secondary"
      selectors = [
        {
          namespace = "default"
          labels = {
            Environment = "test"
            GithubRepo  = "terraform-aws-eks"
            GithubOrg   = "terraform-aws-modules"
          }
        }
      ]

      # Using specific subnets instead of the subnets supplied for the cluster itself
      # TODO: Create a special subnet for Fargate profiles
      subnet_ids = module.vpc.private_subnets

      tags = var.tags
    }
  }




  create_aws_auth_configmap = false # non-default and very important
  
  manage_aws_auth_configmap = true

  # todo figured out this
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::249446252531:role/Admin"
      username = "mapped-admin"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = var.map_users

  # aws_auth_accounts = [
  #   "777777777777",
  #   "888888888888",
  # ]

  # tags = var.tags # Using default tags
}
