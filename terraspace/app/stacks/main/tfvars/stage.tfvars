tags = {
  environment = "stage"
  project     = "magz8s"
  terraform   = "true"
  cost-center = "magz8s"
}


# This is an additional user. Cluster cratetor can always accees it.
map_users = [
  {
    userarn  = "arn:aws:iam::249446252531:user/non-root"
    username = "non-root"
    groups   = ["system:masters"]
  }
]


vpc_cidr = "10.0.0.0/16"