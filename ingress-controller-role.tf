
resource "aws_iam_role" "ingress_controller" {
  name               = "aws-load-balancer-controller"
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

  inline_policy { 
    name = "some_inline_policy"

# todo narrow down permissions to "reource ArnEquals" https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/installation/
    policy = <<POLICY
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect" : "Allow",
      "Action" : [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions",
        "autoscaling:DescribeScalingActivities"
      ],
      "Resource" : ["*"]
    },
    {
      "Effect" : "Allow",
      "Action" : [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeInstanceTypes",
        "eks:DescribeNodegroup"
      ],
      "Resource" : ["*"]
    }
  ]
}
POLICY
  
  }
}



