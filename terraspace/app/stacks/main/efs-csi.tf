module "efs" {
  source  = "cloudposse/efs/aws"
  version = "0.32.7"
  # insert the 18 required variables here

  # namespace = "static-assets"
  # stage     = "prod"
  name    = local.eks_cluser_name
  region  = data.aws_region.current.id
  vpc_id  = module.vpc.vpc_id
  # one mount target per AZ
  subnets = module.vpc.private_subnets
  # zone_id   = [var.aws_route53_dns_zone_id]

  allowed_security_group_ids = [module.eks.node_security_group_id]

  access_points = {
    # "" means / root path
    "" = {
      posix_user = {
        gid            = "0"
        uid            = "0"
        secondary_gids = "1001,1002,1003"
      }
      creation_info = {
        gid         = "0"
        uid         = "0"
        permissions = "0755"
      }
    }
  }
  # tags

}
resource "aws_iam_policy" "efs" {
  name   = "AllowEFS-${local.eks_cluser_name}"
  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:DescribeAccessPoints",
        "elasticfilesystem:DescribeFileSystems",
        "elasticfilesystem:DescribeMountTargets",
        "ec2:DescribeAvailabilityZones"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:CreateAccessPoint"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/efs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "elasticfilesystem:DeleteAccessPoint",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/efs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
  EOF
}

resource "aws_iam_role" "efs" {
  name               = "${local.eks_cluser_name}_efs"
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${module.eks.oidc_provider_arn}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity"
        }
    ]
}
POLICY

  managed_policy_arns = [aws_iam_policy.efs.arn]

}



# module "iam_assumable_role_efs" {
#   source       = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   version      = "~> v3.10.0"
#   create_role  = true
#   role_name    = "eks-efs-${local.eks_cluser_name}"
#   provider_url = var.cluster_oidc_issuer_url
#   role_policy_arns = [
#     aws_iam_policy.efs.arn
#   ]
#   oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
# }



