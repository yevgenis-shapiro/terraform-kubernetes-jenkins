data "aws_caller_identity" "current" {}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
}

resource "aws_iam_role" "jenkins_backup_role" {
  depends_on = [kubernetes_namespace.jenkins]
  name       = format("%s-%s-%s", var.jenkins_config.environment, var.jenkins_config.name, "jenkins-backup-role")
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.jenkins_config.oidc_provider}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${var.jenkins_config.oidc_provider}:aud" = "sts.amazonaws.com",
            "${var.jenkins_config.oidc_provider}:sub" = "system:serviceaccount:jenkins:sa-jenkins"
          }
        }
      }
    ]
  })
  inline_policy {
    name = "AllowS3PutObject"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "kms:DescribeCustomKeyStores",
            "kms:ListKeys",
            "kms:DeleteCustomKeyStore",
            "kms:GenerateRandom",
            "kms:UpdateCustomKeyStore",
            "kms:ListAliases",
            "kms:DisconnectCustomKeyStore",
            "kms:CreateKey",
            "kms:ConnectCustomKeyStore",
            "kms:CreateCustomKeyStore"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:*",
            "s3-object-lambda:*"
          ],
          "Resource" : "*"
        }
      ]
    })
  }
}

resource "kubernetes_service_account" "sa_jenkins" {
  metadata {
    name      = "sa-jenkins"
    namespace = "jenkins"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins_backup_role.arn
    }
  }
}

resource "helm_release" "jenkins" {
  depends_on = [kubernetes_namespace.jenkins]
  name       = "jenkins"
  chart      = "jenkins"
  timeout    = 600
  version    = var.chart_version
  namespace  = var.namespace
  repository = "https://charts.jenkins.io/"
  values = [
    templatefile("${path.module}/helm/values.yaml", {
      hostname            = var.jenkins_config.hostname
      storage_class_name  = var.jenkins_config.storage_class_name
      jenkins_volume_size = var.jenkins_config.jenkins_volume_size
    }),
    var.jenkins_config.values_yaml
  ]
}

data "kubernetes_secret" "jenkins" {
  depends_on = [helm_release.jenkins]
  metadata {
    name      = "jenkins"
    namespace = var.namespace
  }
}

#Created a jenkins backup cronjob, internally uses jenkins master pvc to make a zip file and upload it to s3.
#To use this please create a S3 bucket and pass the name of the bucket along with other varaibles.
resource "kubernetes_cron_job_v1" "jenkins_backup_cron" {
  depends_on = [kubernetes_namespace.jenkins]
  count      = var.jenkins_config.enable_backup ? 1 : 0
  metadata {
    name      = "jenkins-backup-cron"
    namespace = "jenkins"
  }
  spec {
    schedule = var.jenkins_config.backup_schedule
    job_template {
      metadata {
        name      = "jenkins-backup-job"
        namespace = "jenkins"
      }
      spec {
        template {
          metadata {}
          spec {
            service_account_name = kubernetes_service_account.sa_jenkins.metadata[0].name
            container {
              name    = "jenkins-backup"
              image   = "amazonlinux"
              command = ["/bin/bash", "-c"]
              args = [
                "${templatefile("${path.module}/backup.sh", {
                  backup_bucket_name = var.jenkins_config.backup_bucket_name
              })}"]
              volume_mount {
                name       = "jenkins-home"
                mount_path = "/var/jenkins_home"
              }
              volume_mount {
                name       = "backup"
                mount_path = "/backup"
              }
            }
            restart_policy = "Never"
            volume {
              name = "jenkins-home"
              persistent_volume_claim {
                claim_name = "jenkins"
              }
            }
            volume {
              name = "backup"
              empty_dir {}
            }
            affinity {
              pod_affinity {
                required_during_scheduling_ignored_during_execution {
                  label_selector {
                    match_labels = {
                      "app.kubernetes.io/name" = "jenkins"
                    }
                  }
                  topology_key = "kubernetes.io/hostname"
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "time_sleep" "wait_120_sec" {
  depends_on      = [helm_release.jenkins]
  create_duration = "120s"
}

# Creating a pod for jenkins restore, which will get the backup.zip from S3 and overwrite the content to jenkins home directory.
# Always restart jenkisn to reflect the changes.
resource "kubernetes_pod" "jenkins_restore" {
  depends_on = [kubernetes_namespace.jenkins, time_sleep.wait_120_sec]
  count      = var.jenkins_config.restore_backup ? 1 : 0
  metadata {
    name      = "jenkins-restore"
    namespace = "jenkins"
  }
  spec {
    service_account_name = kubernetes_service_account.sa_jenkins.metadata[0].name
    container {
      name    = "jenkins-restore"
      image   = "amazonlinux"
      command = ["/bin/bash", "-c"]
      args = [
        "${templatefile("${path.module}/restore.sh", {
          backup_bucket_name  = var.jenkins_config.backup_bucket_name,
          backup_restore_date = var.jenkins_config.backup_restore_date
      })}"]
      volume_mount {
        name       = "jenkins-home"
        mount_path = "/var/jenkins_home"
      }
      volume_mount {
        name       = "restore"
        mount_path = "/restore"
      }
    }
    restart_policy = "Never"
    volume {
      name = "jenkins-home"
      persistent_volume_claim {
        claim_name = "jenkins"
      }
    }
    volume {
      name = "restore"
      empty_dir {}
    }
    affinity {
      pod_affinity {
        required_during_scheduling_ignored_during_execution {
          label_selector {
            match_labels = {
              "app.kubernetes.io/name" = "jenkins"
            }
          }
          topology_key = "kubernetes.io/hostname"
        }
      }
    }
  }
}
