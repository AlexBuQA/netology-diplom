variable "yc_token" {
  type        = string
  description = "Yandex.Cloud OAuth or IAM token"
  sensitive   = true
}

variable "yc_cloud_id" {
  type        = string
  description = "Yandex.Cloud Cloud ID"
}

variable "yc_folder_id" {
  type        = string
  description = "Yandex.Cloud Folder ID"
}

variable "ycr_name" {
  type        = string
  description = "Имя Yandex Container Registry"
  default     = "abuzhor-registry"
}

variable "ssh_public_key" {
  type        = string
  description = "Публичный SSH-ключ для доступа на ВМ под пользователем ubuntu"
}
