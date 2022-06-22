variable "tags"  {
    description = "Tags common for every resouce in this project"
    type = object({environment=string, project=string, terraform=bool, cost-center=string })
}


variable "map_users"  {
    description = "Users to add to the cluster"
    type = list(object({userarn=string, username=string, groups = list(string)  }))
}


