before("apply",
  execute: "echo 'app/stacks/main/config/hooks/terraform.rb: test stack before hook for terraform apply'",
)

after("apply",
  execute: "echo 'app/stacks/main/config/hooks/terraform.rb: test stack after hook for terraform apply'"
)

before("destroy",
  label: "Pruning loadbalancers created by kubernetes ingress controller",
  # TODO more precise filter , not just vpc id. Seems that terraform output does not work here. Try  terraspace  output main     
  execute: "echo 'app/stacks/main/config/hooks/terraform.rb: test stack before hook for terraform destroy';
  test $(terraform output -json  eks_vpc )  || { echo '\u001b[33m  Unable to get eks_vpc output. \u001b[0m' ;  exit 1 }
  VPC_ID=$(terraform output -json  eks_vpc   | jq -r '.vpc_id' )
  aws elbv2 delete-load-balancer --load-balancer-arn $(aws elbv2  describe-load-balancers --output json  | jq -r --arg VPC_ID $VPC_ID '.LoadBalancers[] | select(.VpcId==$VPC_ID) | .LoadBalancerArn ') && echo '\u001b[32m  Pruned ingress load balancers  \u001b[33m  || echo '\u001b[33m  Did not find ingress resources to prune. \u001b[0m' '
  ",
  exit_on_fail: false,
)

after("destroy",
  execute: "echo 'app/stacks/main/config/hooks/terraform.rb: test stack after hook for terraform destroy'"
)



