before("apply",
  execute: "echo 'app/stacks/main/config/hooks/terraform.rb: test stack before hook for terraform apply'",
)

after("apply",
  execute: "echo 'app/stacks/main/config/hooks/terraform.rb: test stack after hook for terraform apply'"
)

before("destroy",
  label: "Pruning loadbalancers created by kubernetes ingress controller",
  execute: "echo 'app/stacks/main/config/hooks/terraform.rb: test stack before hook for terraform destroy';
  terraform output eks_vpc.arn ;
  aws elbv2 delete-load-balancer --load-balancer-arn $(terraform output eks_vpc.arn) || echo '\u001b[33m  Did not find ingress resources to prune. \u001b[0m' && echo '\u001b[32m  Pruned ingress load balancers  \u001b[33m'
  ",
)

after("destroy",
  execute: "echo 'app/stacks/main/config/hooks/terraform.rb: test stack after hook for terraform destroy'"
)
