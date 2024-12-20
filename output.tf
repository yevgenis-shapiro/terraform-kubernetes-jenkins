output "jenkins" {
  description = "Jenkins_Info"
  value = {
    username = nonsensitive(data.kubernetes_secret.jenkins.data["jenkins-admin-user"]),
    password = nonsensitive(data.kubernetes_secret.jenkins.data["jenkins-admin-password"]),
    url      = var.jenkins_config.hostname
  }
}
