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

# S3-бакет, в котором будет храниться terraform.tfstate основной инфраструктуры.
# Имя бакета должно быть уникальным в пределах всего Yandex Object Storage —
# при необходимости поменяйте "abuzhor-diplom-tfstate" на своё.
resource "yandex_storage_bucket" "terraform_state" {
  bucket     = var.bucket_name
  access_key = var.sa_access_key
  secret_key = var.sa_secret_key

  # Версионирование state-файла — хорошая практика: можно откатиться к предыдущей версии.
  versioning {
    enabled = true
  }
}
