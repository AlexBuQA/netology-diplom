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

variable "sa_access_key" {
  type        = string
  description = "Service account access key (из этапа service-account)"
  sensitive   = true
}

variable "sa_secret_key" {
  type        = string
  description = "Service account secret key (из этапа service-account)"
  sensitive   = true
}

variable "bucket_name" {
  type        = string
  description = "Имя S3-бакета для хранения Terraform state"
  default     = "abuzhor-diplom-tfstate"
}
