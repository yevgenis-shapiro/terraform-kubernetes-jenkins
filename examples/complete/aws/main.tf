locals {
  name        = ""
  region      = ""
  environment = ""
  additional_tags = {
    Owner      = "organization_name"
    Expires    = "Never"
    Department = "Engineering"
  }
  oidc_provider = replace(
    data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer,
    "/^https:///",
    ""
  )
}

module "s3_bucket_jenkins_backup" {
  source                   = "terraform-aws-modules/s3-bucket/aws"
  version                  = "4.1.2"
  create_bucket            = true
  bucket                   = format("%s-%s-%s", local.environment, local.name, "jenkins-backup")
  acl                      = "private"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


module "jenkins" {
  source     = "squareops/jenkins/kubernetes"
  version    = "2.2.2"
  depends_on = [module.s3_bucket_jenkins_backup]
  jenkins_config = {
    name                = local.name
    environment         = local.environment
    oidc_provider       = local.oidc_provider
    hostname            = "jenkins.squareops.com"
    values_yaml         = file("./helm/values.yaml")
    storage_class_name  = "infra-service-sc"
    jenkins_volume_size = "10Gi"
    enable_backup       = true                                         # true for enable backup
    backup_schedule     = "0 6 * * *"                                  # Set Cron for the job
    backup_bucket_name  = module.s3_bucket_jenkins_backup.s3_bucket_id # s3 bucket name
    restore_backup      = true                                         # true for restore the backup
    backup_restore_date = ""                                           # Date of backup
  }
}
