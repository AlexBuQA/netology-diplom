terraform {
  required_version = ">= 1.6.0"

  # State основной инфраструктуры хранится в S3-бакете, созданном на этапе backend.
  # В блоке backend нельзя использовать переменные, поэтому ключи доступа
  # передаются отдельно через файл backend.hcl:
  #   terraform init -backend-config=backend.hcl
  backend "s3" {
    endpoints = { s3 = "https://storage.yandexcloud.net" }
    bucket    = "abuzhor-diplom-tfstate"
    key       = "terraform.tfstate"
    region    = "ru-central1"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
  }

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
}
