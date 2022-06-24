resource "aws_iam_user" "cluster_user" {
  name = "cluster-user"
  path = "/${var.tags.project}/${var.tags.environment}/"
  # tags = var.tags
}


resource "aws_s3_bucket" "k8s_bucket" {
    bucket = "${var.tags.project}-${var.tags.environment}"
    # tags = var.tags
}


# resource "aws_iam_policy" "s3" {
#     name        = "storageTestS3FullAccess"
#     path        = "/"
#     description = "Allow full access to ${var.tags.project}-${var.tags.environment} s3"
#     tags = local.common_tags
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

resource "aws_iam_user_policy" "s3" {
  name = "${var.tags.project}-${var.tags.environment}"
  user = aws_iam_user.cluster_user.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor1",
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${var.tags.project}-${var.tags.environment}",
        "arn:aws:s3:::${var.tags.project}-${var.tags.environment}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_access_key" "s3" {
  user = aws_iam_user.cluster_user.name
}

output "aws_iam_smtp_password_v4" {
  value = aws_iam_access_key.s3.ses_smtp_password_v4
  sensitive = true
}

# terraform output -raw id            
output "id" {
  value = aws_iam_access_key.s3.id
  sensitive = true
}

#  terraform output -raw secret
output "secret" {
  value = aws_iam_access_key.s3.secret
  sensitive = true
}
