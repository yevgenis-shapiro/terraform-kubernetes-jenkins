variable "jenkins_config" {
  type = any
  default = {
    name                = ""
    environment         = ""
    oidc_provider       = ""
    hostname            = ""
    storage_class_name  = ""
    jenkins_volume_size = ""
    values_yaml         = ""
    enable_backup       = false
    backup_schedule     = ""
    backup_bucket_name  = ""
    restore_backup      = false
    backup_restore_date = ""
  }
  description = "Specify the configuration settings for Jenkins, including the hostname, storage options, and custom YAML values."
}

variable "namespace" {
  type        = string
  default     = "jenkins"
  description = "Name of the Kubernetes namespace where the Jenkins deployment will be deployed."
}

variable "chart_version" {
  type        = string
  default     = "5.4.2"
  description = "Version of the Jenkins chart that will be used to deploy Jenkins application."
}
