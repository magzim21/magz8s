tags = {
  environment = "stage"
  project     = "magz8s"
  terraform   = "true"
  cost-center = "magz8s"
}


map_users = [
  {
    userarn  = "arn:aws:iam::249446252531:user/non-root"
    username = "non-root"
    groups   = ["system:masters"]
  }
]
