before("apply",
  execute: "echo 'app/stacks/main/config/hooks/terraform.rb: test stack before hook for terraform apply'",
)

after("apply",
  execute: "echo 'app/stacks/main/config/hooks/terraform.rb: test stack after hook for terraform apply'
  KUBECONFIG=\"./$(ls kubeconfig*)\" kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d
  "
)

SCRIPT = <<~EOS
echo 'app/stacks/main/config/hooks/terraform.rb: test stack before hook for terraform destroy';
terraform output  -json  eks_vpc  || { echo '\u001b[33m  Unable to get eks_vpc output. \u001b[0m' ;  exit 1 ; }
VPC_ID=$(terraform output  -json  eks_vpc   | jq -r '.vpc_id' )
LBs_PRUNE=$(aws elbv2  describe-load-balancers --output json  | jq -r --arg VPC_ID $VPC_ID '.LoadBalancers[] | select(.VpcId==$VPC_ID) | .LoadBalancerArn ')
for LB in $LBs_PRUNE ; do
  aws elbv2 delete-load-balancer --load-balancer-arn $LB  && echo '\u001b[32m  Pruned ingress load balancers  \u001b[33m'  || echo '\u001b[33m  Did not find ingress resources to prune. \u001b[0m' 
done

CLUSTER_ID=$(terraform output  -json  eks   | jq -r '.cluster_id')
SG_IDs=$(
  aws ec2 describe-security-groups --output json | 
  jq -r --arg  CLUSTER_ID $CLUSTER_ID '.SecurityGroups[] | 
    select(
        ((.Tags |  index({"Key":"elbv2.k8s.aws/cluster","Value":$CLUSTER_ID}) ) and 
        (.Tags |  index({"Key":"elbv2.k8s.aws/resource","Value":"backend-sg"}) ) ) or
        (.Tags |  index({"Key":("kubernetes.io/cluster/" + $CLUSTER_ID),"Value":"owned"}) )
        )
    | .GroupId '


)
for SG in $SG_IDs ; do
  aws ec2 delete-security-group --group-id $SG  && echo '\u001b[32m  Pruned security group $SG  \u001b[33m' 
done
EOS

before("destroy",
  label: "Pruning loadbalancers created by kubernetes ingress controller",
  # TODO more precise filter , not just vpc id. Seems that terraform output does not work here. Try  terraspace  output main     
  execute: SCRIPT,
  exit_on_fail: false,
)

after("destroy",
  execute: "echo 'app/stacks/main/config/hooks/terraform.rb: test stack after hook for terraform destroy'"
)



