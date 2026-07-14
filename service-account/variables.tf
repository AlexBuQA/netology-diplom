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
