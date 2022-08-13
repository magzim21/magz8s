# This file stores global veriables. Meaning variables are applied to every environment TS_ENV.
repo_owner = "magzim21"


# This is an additional user. Cluster cratetor can always accees it.
map_users = [
  {
    userarn  = "arn:aws:iam::249446252531:user/non-root"
    username = "non-root"
    groups   = ["system:masters"]
  }
]
