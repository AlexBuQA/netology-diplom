terraform {
  required_version = ">= 1.6.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100.0"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
}

# Сервисный аккаунт, от имени которого Terraform будет управлять инфраструктурой.
resource "yandex_iam_service_account" "terraform" {
  name        = "tf-sa-diplom"
  description = "Service account for Terraform (Александра Бужор, дипломный проект)"
}

# Даём аккаунту роль editor на весь каталог (folder).
# По заданию нельзя использовать права суперпользователя (admin) — editor достаточно.
resource "yandex_resourcemanager_folder_iam_binding" "editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.terraform.id}"
  ]
}

# Статический ключ доступа (access_key / secret_key) — понадобится для S3-бэкенда Terraform.
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.terraform.id
  description        = "Static access key for Terraform S3 backend"
}
