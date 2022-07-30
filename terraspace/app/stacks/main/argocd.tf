





resource "null_resource" "kubeconfig" {
  # todo: maybe remove this trigger and simplify script.
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {

    command = <<SCRIPT
    unset -e
    unset -o pipefail

    aws eks --region ${data.aws_region.current.id} update-kubeconfig --name ${var.tags.project}-${var.tags.environment} 	--kubeconfig ${local.kubeconfig_path} ||
    {
      # If previous command errored, means cluster is not ready yet
      sleep 300
      aws eks --region ${data.aws_region.current.id} update-kubeconfig --name ${var.tags.project}-${var.tags.environment} 	--kubeconfig ${local.kubeconfig_path}
      }
      
    kubectl create namespace argocd; 
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml ; 
  
SCRIPT
    environment = {
      "KUBECONFIG" : "${local.kubeconfig_path}"
    }
    interpreter = ["/bin/bash", "-c" ]
  }
}

# Todo output argocd 




# template here 
resource "null_resource" "gitops_branch" {
  # triggers = {
  #   always_run = "${timestamp()}"
  # }

  # Preparing new branch for gitops/argocd purpose
  provisioner "local-exec" {
    command = <<SCRIPT
      git pull

      branch=gitops
      existed_in_local=$(git branch --list $branch)

      if [[ -z $\{existed_in_local\} ]]; then
          git checkout $branch
      else
          git checkout -b $branch
      fi

SCRIPT
    interpreter = ["/bin/bash", "-c" ]

  }
}


resource "local_file" "external_dns" {
  content      = templatefile("${path.module}/../../../../../../argo-projects-templates/addons/external-dns.yaml.tftpl", {})
  filename = "${path.module}/../../../../../../argo-projects/addons/external-dns.yaml"
  depends_on = [null_resource.gitops_branch]
}
resource "local_file" "cluster_autoscaler" {
  content      = templatefile("${path.module}/../../../../../../argo-projects-templates/addons/cluster-autoscaler.yaml.tftpl", {})
  filename = "${path.module}/../../../../../../argo-projects/addons/cluster-autoscaler.yaml"
  depends_on = [null_resource.gitops_branch]
}
resource "local_file" "aws_efs_csi_driver" {
  content      = templatefile("${path.module}/../../../../../../argo-projects-templates/addons/aws-efs-csi-driver.yaml.tftpl", {})
  filename = "${path.module}/../../../../../../argo-projects/addons/aws-efs-csi-driver.yaml"
  depends_on = [null_resource.gitops_branch]
}
resource "local_file" "ingress_controller" {
  content      = templatefile("${path.module}/../../../../../../argo-projects-templates/addons/ingress-controller.yaml.tftpl", {})
  filename = "${path.module}/../../../../../../argo-projects/addons/ingress-controller.yaml"
  depends_on = [null_resource.gitops_branch]
}
resource "local_file" "grafana" {
  content      = templatefile("${path.module}/../../../../../../argo-projects-templates/monitoring/grafana.yaml.tftpl", {})
  filename = "${path.module}/../../../../../../argo-projects/monitoring/grafana.yaml"
  depends_on = [null_resource.gitops_branch]
}
resource "local_file" "prometheus_stack" {
  content      = templatefile("${path.module}/../../../../../../argo-projects-templates/monitoring/prometheus-stack.yaml.tftpl", {})
  filename = "${path.module}/../../../../../../argo-projects/monitoring/prometheus-stack.yaml"
  depends_on = [null_resource.gitops_branch]
}
resource "local_file" "grafana_mimir_custom" {
  content      = templatefile("${path.module}/../../../../../../argo-projects-templates/monitoring/values/grafana-mimir-custom.yaml.tftpl", {})
  filename = "${path.module}/../../../../../../argo-projects/monitoring/values/grafana-mimir-custom.yaml"
  depends_on = [null_resource.gitops_branch]
}
resource "local_file" "grafana_mimir_small_cluster" {
  content      = templatefile("${path.module}/../../../../../../argo-projects-templates/monitoring/values/grafana-mimir-small-cluster.yaml.tftpl", {})
  filename = "${path.module}/../../../../../../argo-projects/monitoring/values/grafana-mimir-small-cluster.yaml"
  depends_on = [null_resource.gitops_branch]
}
resource "local_file" "grafana_mimir" {
  content      = templatefile("${path.module}/../../../../../../argo-projects-templates/monitoring/grafana-mimir.yaml.tftpl", {})
  filename = "${path.module}/../../../../../../argo-projects/monitoring/grafana-mimir.yaml"
  depends_on = [null_resource.gitops_branch]
}
resource "local_file" "argo_monitoring_project" {
  content      = templatefile("${path.module}/../../../../../../argo-projects-templates/monitoring/argo-monitoring-project.yaml.tftpl", {})
  filename = "${path.module}/../../../../../../argo-projects/monitoring/argo-monitoring-project.yaml"
  depends_on = [null_resource.gitops_branch]
}
resource "local_file" "loki" {
  content      = templatefile("${path.module}/../../../../../../argo-projects-templates/monitoring/loki.yaml.tftpl", {})
  filename = "${path.module}/../../../../../../argo-projects/monitoring/loki.yaml"
  depends_on = [null_resource.gitops_branch]
}
resource "local_file" "game_2048" {
  content      = templatefile("${path.module}/../../../../../../argo-projects-templates/apps/game-2048.yaml.tftpl", {})
  filename = "${path.module}/../../../../../../argo-projects/apps/game-2048.yaml"
  depends_on = [null_resource.gitops_branch]



}
resource "local_file" "root_application" {
  content      = templatefile("${path.module}/../../../../../../root-application.yaml.tftpl", {})
  filename = "${path.module}/../../../../../../root-application.yaml"
  depends_on = [null_resource.gitops_branch]

}

resource "null_resource" "push_changes" {
  provisioner "local-exec" {

    command = <<SCRIPT
      user_repo=$(git remote -v | awk -F ":" 'NR==1{print $2}'  | awk -F ".git" '{print $1}')
      branch="gitops"git 
      repo_root_dir=$(git rev-parse --show-toplevel) 

      git add $repo_root_dir
      git commit -am "feat: new cluster - new yaml variables" 
      git push --set-upstream origin gitops                 
      kubectl apply -f https://raw.githubusercontent.com/$user_repo/$branch/root-application.yaml;

SCRIPT
    environment = {
      "KUBECONFIG" : "${local.kubeconfig_path}"
    }
    interpreter = ["/bin/bash", "-c" ]
  }
  depends_on = [local_file.root_application]
}
