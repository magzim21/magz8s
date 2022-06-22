module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.23.0"

  cluster_name    = var.tags.project
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

  vpc_id     = aws_default_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

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
    blue = {}
    green = {
      min_size     = 2
      max_size     = 10
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size = "30"
    }
  }

  # Fargate Profile(s)
  # fargate_profiles = {
  #   default = {
  #     name = "default"
  #     selectors = [
  #       {
  #         namespace = "default"
  #       }
  #     ]
  #   }
  # }

  create_aws_auth_configmap = true
  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::249446252531:instance-profile/Admin"
      username = "mapped-admin"
      groups   = ["system:masters"]
    },
  ]

  # aws_auth_users = var.map_users

  # aws_auth_accounts = [
  #   "777777777777",
  #   "888888888888",
  # ]

  tags = var.tags
}
