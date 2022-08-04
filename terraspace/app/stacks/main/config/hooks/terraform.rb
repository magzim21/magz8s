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
  terraform output  -json  eks_vpc  || { echo '\u001b[33m  Unable to get eks_vpc output. \u001b[0m' ;  exit 1 ; }
  VPC_ID=$(terraform output  -json  eks_vpc   | jq -r '.vpc_id' )
  LBs_PRUNE=$(aws elbv2  describe-load-balancers --output json  | jq -r --arg VPC_ID $VPC_ID '.LoadBalancers[] | select(.VpcId==$VPC_ID) | .LoadBalancerArn ')
  for LB in $LBs_PRUNE ; do
    aws elbv2 delete-load-balancer --load-balancer-arn $LB  && echo '\u001b[32m  Pruned ingress load balancers  \u001b[33m'  || echo '\u001b[33m  Did not find ingress resources to prune. \u001b[0m' 
  done
  
  CLUSTER_ID=$(terraform output  -json  eks   | jq -r '.cluster_id')
  LB_ARN=$(
    aws elbv2 describe-tags --resource-arns $(aws elbv2  describe-load-balancers --output json   | jq -r '.LoadBalancers[] | .LoadBalancerArn')  --output json  |
      jq -r --arg  CLUSTER_ID $CLUSTER_ID  '.TagDescriptions[] |
        select(
            (.Tags |  index({\"Key\":\"elbv2.k8s.aws/cluster\",\"Value\":$CLUSTER_ID}) ) and 
            (.Tags | index({\"Key\":\"ingress.k8s.aws/resource\",\"Value\":\"LoadBalancer\"}) ) )
        | .ResourceArn '  && echo '\u001b[32m  Pruned security groups  \u001b[33m'  || echo '\u001b[33m  Did not find security groups to prune. \u001b[0m' 
)

  ",
  exit_on_fail: false,
)

after("destroy",
  execute: "echo 'app/stacks/main/config/hooks/terraform.rb: test stack after hook for terraform destroy'"
)



