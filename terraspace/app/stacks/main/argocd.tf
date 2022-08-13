resource "null_resource" "sleep_eks" {
  # todo: maybe remove this trigger and simplify script.
  # triggers = {
  #   always_run = "${timestamp()}"
  # }
  provisioner "local-exec" {

    command = "sleep 400"
    when    = create
  }
  depends_on = [
    module.eks
  ]
}



resource "null_resource" "kubeconfig" {
  # todo: maybe remove this trigger and simplify script.
  # triggers = {
  #   always_run = "${timestamp()}"
  # }
  # Todo: rewrite this to a python script
  provisioner "local-exec" {
    when = create

    command = <<SCRIPT
      branch=${local.gitops_branch}
      existed_in_local=$(git branch --list $branch)
      repo_owner=${var.repo_owner}

      if [[ ! -z $existed_in_local ]]; then
          echo Branch $branch already exists
          git checkout $branch 
          git stash
          git reset --hard main
      else
          git checkout -b $branch
      fi

      aws eks --region ${data.aws_region.current.id} update-kubeconfig --name ${local.eks_cluser_name} 	--kubeconfig ${local.kubeconfig_path};
      
      kubectl create namespace argocd; 
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml ; 


  
SCRIPT
    environment = {
      "KUBECONFIG" : "${local.kubeconfig_path}"
    }
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [
    null_resource.sleep_eks
  ]
}

# Todo output argocd 




resource "local_file" "external_dns" {
  content = templatefile("${path.module}/../../../../../../argo-projects-templates/addons/external-dns.yaml.tftpl", {
    "role-arn" : aws_iam_role.external_dns_controller.arn
  })
  filename   = "${path.module}/../../../../../../argo-projects/addons/external-dns.yaml"
  depends_on = [null_resource.kubeconfig, aws_iam_role.external_dns_controller]
}
resource "local_file" "cluster_autoscaler" {
  content = templatefile("${path.module}/../../../../../../argo-projects-templates/addons/cluster-autoscaler.yaml.tftpl", {
    "clusterName" : local.eks_cluser_name,
    "awsRegion" : data.aws_region.current.id,
    "cloudProvider" : "aws",
    "role-arn" : aws_iam_role.cluster_autoscaler.arn
  })
  filename   = "${path.module}/../../../../../../argo-projects/addons/cluster-autoscaler.yaml"
  depends_on = [null_resource.kubeconfig, aws_iam_role.cluster_autoscaler]
}
resource "local_file" "aws_efs_csi_driver" {
  content = templatefile("${path.module}/../../../../../../argo-projects-templates/addons/aws-efs-csi-driver.yaml.tftpl", {
    aws_image_registry = local.aws_image_registry
    efs_id             = module.efs.id
    role-arn           = aws_iam_role.efs.arn
  })
  filename   = "${path.module}/../../../../../../argo-projects/addons/aws-efs-csi-driver.yaml"
  depends_on = [null_resource.kubeconfig, module.efs]
}
resource "local_file" "ingress_controller" {
  content = templatefile("${path.module}/../../../../../../argo-projects-templates/addons/ingress-controller.yaml.tftpl", {
    "clusterName" : "${var.tags.project}-${var.tags.environment}",
    "role-arn" : aws_iam_role.ingress_controller.arn
  })
  filename   = "${path.module}/../../../../../../argo-projects/addons/ingress-controller.yaml"
  depends_on = [null_resource.kubeconfig, aws_iam_role.ingress_controller]
}
# resource "local_file" "grafana" {
#   triggers = {
#     always_run = "${timestamp()}"
#   }
# #   content    = templatefile("${path.module}/../../../../../../argo-projects-templates/monitoring/grafana.yaml.tftpl", {})
#   filename   = "${path.module}/../../../../../../argo-projects/monitoring/grafana.yaml"
#   depends_on = [null_resource.kubeconfig]
# }
resource "local_file" "prometheus_stack" {
  content    = templatefile("${path.module}/../../../../../../argo-projects-templates/monitoring/prometheus-stack.yaml.tftpl", {})
  filename   = "${path.module}/../../../../../../argo-projects/monitoring/prometheus-stack.yaml"
  depends_on = [null_resource.kubeconfig]
}
resource "local_file" "grafana_mimir_custom" {
  content = templatefile("${path.module}/../../../../../../argo-projects-templates/monitoring/values/grafana-mimir-custom.yaml.tftpl", {
    "s3_bucket_admin" : aws_s3_bucket.metrics_admin.id,
    "s3_bucket_ruler" : aws_s3_bucket.metrics_ruler.id,
    "s3_bucket_tsdb" : aws_s3_bucket.metrics_tsdb.id,
    "region" : data.aws_region.current.id,
    "gitops_branch" : local.gitops_branch
  })
  filename   = "${path.module}/../../../../../../argo-projects/monitoring/values/grafana-mimir-custom.yaml"
  depends_on = [null_resource.kubeconfig]
}
resource "local_file" "grafana_mimir" {
  content = templatefile("${path.module}/../../../../../../argo-projects-templates/monitoring/grafana-mimir.yaml.tftpl", {
    "repo_owner" : var.repo_owner,
    "repo_name" : var.repo_name,
    "role-arn" : aws_iam_role.mimr_cluster_minio.arn,
    "targetRevision" : local.gitops_branch
  })
  filename   = "${path.module}/../../../../../../argo-projects/monitoring/grafana-mimir.yaml"
  depends_on = [null_resource.kubeconfig]
}
resource "local_file" "argo_monitoring_project" {
  content    = templatefile("${path.module}/../../../../../../argo-projects-templates/monitoring/argo-monitoring-project.yaml.tftpl", {})
  filename   = "${path.module}/../../../../../../argo-projects/monitoring/argo-monitoring-project.yaml"
  depends_on = [null_resource.kubeconfig]
}
resource "local_file" "loki" {
  content    = templatefile("${path.module}/../../../../../../argo-projects-templates/monitoring/loki.yaml.tftpl", {})
  filename   = "${path.module}/../../../../../../argo-projects/monitoring/loki.yaml"
  depends_on = [null_resource.kubeconfig]
}
resource "local_file" "game_2048" {
  content = templatefile("${path.module}/../../../../../../argo-projects-templates/apps/game-2048.yaml.tftpl", {
    "repo_owner" : var.repo_owner,
    "repo_name" : var.repo_name,
    "targetRevision" : local.gitops_branch
  })
  filename   = "${path.module}/../../../../../../argo-projects/apps/game-2048.yaml"
  depends_on = [null_resource.kubeconfig]
}
resource "local_file" "fargate_sample_app" {
  content = templatefile("${path.module}/../../../../../../argo-projects-templates/apps/fargate-sample-app.yaml.tftpl", {
    "repo_owner" : var.repo_owner,
    "repo_name" : var.repo_name,
    "targetRevision" : local.gitops_branch
  })
  filename   = "${path.module}/../../../../../../argo-projects/apps/fargate-sample-app.yaml"
  depends_on = [null_resource.kubeconfig]
}
resource "local_file" "root_application" {
  content = templatefile("${path.module}/../../../../../../root-application.yaml.tftpl", {
    "repo_owner" : var.repo_owner,
    "repo_name" : var.repo_name
    "targetRevision" : local.gitops_branch
  })
  filename   = "${path.module}/../../../../../../root-application.yaml"
  depends_on = [null_resource.kubeconfig]

}

resource "null_resource" "push_changes" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    when = create
    # Todo: rewrite this to a python script
    command = <<SCRIPT
      set -euo pipefail

      branch=${local.gitops_branch}
      repo_owner=${var.repo_owner}
      repo_name=$(basename $(git rev-parse --show-toplevel))
      repo_root_dir=$(git rev-parse --show-toplevel) 


      git add $repo_root_dir/argo-projects   $repo_root_dir/root-application.yaml
      git commit -am "feat: new cluster - new yaml variables" 
      git push --set-upstream origin $branch -f 

      kubectl apply -f https://raw.githubusercontent.com/$repo_owner/$repo_name/$branch/root-application.yaml 

      git checkout main
SCRIPT
    environment = {
      "KUBECONFIG" : "${local.kubeconfig_path}"
    }
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [local_file.root_application, null_resource.sleep_eks, null_resource.kubeconfig]
}

