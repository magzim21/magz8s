variable "repo_owner" {
  description = "Github username for ArgoCD apps source"
}

variable "repo_name" {
  description = "Github reponame for ArgoCD apps source"
  default = "magz8s"
}

variable "tags" {
  description = "Tags common for every resouce in this project"
  type        = object({ environment = string, project = string, terraform = bool, cost-center = string })
}


variable "map_users" {
  description = "Users to add to the cluster"
  type        = list(object({ userarn = string, username = string, groups = list(string) }))
}


variable "vpc_cidr" {
  description = "A VPC CIDR"
  type        = string
}

