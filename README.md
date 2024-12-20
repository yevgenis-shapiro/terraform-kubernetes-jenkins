## Jenkins is a tool for continuous integration and delivery workflows
![0_dZsiK1TUZuq8xImf](https://github.com/user-attachments/assets/f957b953-75a6-405f-8bcd-4226e3a8af86)

<br>
Terraform module allows you to run Jenkins inside a cluster, providing improved availability and scalability, which can help manage the deployment, scaling, and configuration of Jenkins.
To use this module, you will need to ensure that your cluster is set up correctly, with shared storage for data persistence and load balancing configured to distribute requests across nodes.


## Important:
This module is compatible with EKS, AKS & GKE which is great news for users deploying the module on an AWS, Azure & GCP cloud. Review the module's documentation, meet specific configuration requirements, and test thoroughly after deployment to ensure everything works as expected.

## Usage Example

```hcl
module "jenkins" {
  source        = "yevgenis-shapiro/jenkins/kubernetes"
  version       = "2.2.2"
  jenkins_config = {
    hostname            = "jenkins.localhost.io"
    values_yaml         = file("./helm/values.yaml")
    storage_class_name  = "infra-service-sc"
    jenkins_volume_size = "10Gi"
    enable_backup       = true   # true for enable backup
    backup_schedule     = "0 6 * * *" # Set Cron for the job
    service_account     = kubernetes_service_account.sa_jenkins.metadata[0].name # service account name
    backup_bucket_name  = module.s3_bucket_jenkins_backup.s3_bucket_id  # s3 bucket name
    restore_backup      = true # true for restore the backup
    backup_restore_date = "2024-07-18" # Date of backup
  }
}

```
- Refer [AWS examples](https://github.com/yevgenis-shapiro/terraform-kubernetes-jenkins/tree/main/examples/complete/aws) for more details.
- Refer [Azure examples](https://github.com/yevgenis-shapiro/terraform-kubernetes-jenkins/tree/main/examples/complete/azure) for more details.
- Refer [GCP examples](https://github.com/yevgenis-shapiro/terraform-kubernetes-jenkins/tree/main/examples/complete/gcp) for more details.


## Backup and Restore
This repository provides a method for backing up and restoring Jenkins using S3 storage.

<b>Usage</b> <br>
To enable backup, set the <b>enable_backup</b> variable to true. Backups will be automatically stored in the configured S3 bucket.

To restore a backup, set the <b>restore_backup</b> variable to true. This will initiate the restoration process from the latest backup available in the S3 bucket.

<b>Important Notes</b> <br>
<ul><li>Ensure to restart the Jenkins service after performing a restore to apply the restored configuration and data.</li>
<li>Backup and restore functionality relies on proper configuration of S3 credentials and bucket permissions.</li></ul>



<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |


## Resources

| Name | Type |
|------|------|
| [aws_iam_role.jenkins_backup_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [helm_release.jenkins](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_cron_job_v1.jenkins_backup_cron](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cron_job_v1) | resource |
| [kubernetes_namespace.jenkins](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_pod.jenkins_restore](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/pod) | resource |
| [kubernetes_service_account.sa_jenkins](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [time_sleep.wait_120_sec](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [kubernetes_secret.jenkins](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Version of the Jenkins chart that will be used to deploy Jenkins application. | `string` | `"5.4.2"` | no |
| <a name="input_jenkins_config"></a> [jenkins\_config](#input\_jenkins\_config) | Specify the configuration settings for Jenkins, including the hostname, storage options, and custom YAML values. | `any` | <pre>{<br>  "backup_bucket_name": "",<br>  "backup_restore_date": "",<br>  "backup_schedule": "",<br>  "enable_backup": false,<br>  "environment": "",<br>  "hostname": "",<br>  "jenkins_volume_size": "",<br>  "name": "",<br>  "oidc_provider": "",<br>  "restore_backup": false,<br>  "storage_class_name": "",<br>  "values_yaml": ""<br>}</pre> | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Name of the Kubernetes namespace where the Jenkins deployment will be deployed. | `string` | `"jenkins"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_jenkins"></a> [jenkins](#output\_jenkins) | Jenkins\_Info |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

