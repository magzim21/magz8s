# This S3 storage is for Grafana Mimir Cluster


resource "aws_s3_bucket" "metrics_admin" {

  bucket = "${var.tags.project}-${var.tags.environment}-metrics-admin"
  # tags = var.tags
  # depends_on = [null_resource.s3_destroy]
}

resource "aws_s3_bucket" "metrics_ruler" {

  bucket = "${var.tags.project}-${var.tags.environment}-metrics-ruler"
  # tags = var.tags
  # depends_on = [null_resource.s3_destroy]
}

resource "aws_s3_bucket" "metrics_tsdb" {

  bucket = "${var.tags.project}-${var.tags.environment}-metrics-tsdb"
  # tags = var.tags
  # depends_on = [null_resource.s3_destroy]
}



resource "aws_iam_role" "mimr_cluster_minio" {
  name               = "${var.tags.project}-${var.tags.environment}-mimir-cluster-minio"
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
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
        "s3:PutAccountPublicAccessBlock",
        "s3:GetAccountPublicAccessBlock",
        "s3:ListAllMyBuckets",
        "s3:ListJobs",
        "s3:CreateJob",
        "s3:HeadBucket",
        "s3:ListBucket"
      ],
      "Resource": "*"
    },
    {
      "Sid": "VisualEditor1",
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${var.tags.project}-${var.tags.environment}",
        "arn:aws:s3:::${var.tags.project}-${var.tags.environment}-mimir/*"
      ]
    }
  ]
}
POLICY

  }
}






# resource "null_resource" "s3_destroy" {
#   provisioner "local-exec" {
#     # Unfortuenetelly can not use variables here or references to other resources
#     command = "aws s3 rm s3://magz8s-stage --recursive"
#     interpreter = ["bash", "-c"]
#     when = "destroy"
#   }
# }


# resource "aws_iam_user" "cluster_user" {
#   name = "cluster-user"
#   path = "/${var.tags.project}/${var.tags.environment}/"
#   # tags = var.tags
# }




# resource "aws_iam_policy" "s3" {
#     name        = "storageTestS3FullAccess"
#     path        = "/"
#     description = "Allow full access to ${var.tags.project}-${var.tags.environment} s3"
#     # tags = var.tags
#     policy      = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "VisualEditor0",
#       "Effect": "Allow",
#       "Action": [
#         "s3:PutAccountPublicAccessBlock",
#         "s3:GetAccountPublicAccessBlock",
#         "s3:ListAllMyBuckets",
#         "s3:ListJobs",
#         "s3:CreateJob",
#         "s3:HeadBucket",
#         "s3:ListBucket"
#       ],
#       "Resource": "*"
#     },
#     {
#       "Sid": "VisualEditor1",
#       "Effect": "Allow",
#       "Action": "s3:*",
#       "Resource": [
#         "arn:aws:s3:::${var.tags.project}-${var.tags.environment}",
#         "arn:aws:s3:::${var.tags.project}-${var.tags.environment}/*"
#       ]
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_user_policy" "s3" {
#   name = "${var.tags.project}-${var.tags.environment}"
#   user = aws_iam_user.cluster_user.name

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "VisualEditor1",
#       "Effect": "Allow",
#       "Action": "s3:*",
#       "Resource": [
#         "arn:aws:s3:::${var.tags.project}-${var.tags.environment}",
#         "arn:aws:s3:::${var.tags.project}-${var.tags.environment}/*"
#       ]
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_access_key" "s3" {
#   user = aws_iam_user.cluster_user.name
# }

# output "aws_iam_smtp_password_v4" {
#   value = aws_iam_access_key.s3.ses_smtp_password_v4
#   sensitive = true
# }

# # terraform output -raw id            
# output "id" {
#   value = aws_iam_access_key.s3.id
#   sensitive = true
# }

# #  terraform output -raw secret
# output "secret" {
#   value = aws_iam_access_key.s3.secret
#   sensitive = true
# }
