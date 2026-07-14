output "bucket_name" {
  value       = yandex_storage_bucket.terraform_state.bucket
  description = "Имя созданного S3-бакета"
}
