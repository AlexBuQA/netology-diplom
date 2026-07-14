output "service_account_id" {
  value       = yandex_iam_service_account.terraform.id
  description = "ID сервисного аккаунта Terraform"
}

# Ключи Terraform-аккаунта. Помечены sensitive — в консоли не отображаются.
# Достать их можно так:
#   terraform output -json service_account_keys | jq -r '.access_key'
#   terraform output -json service_account_keys | jq -r '.secret_key'
output "service_account_keys" {
  value = {
    access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
    secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  }
  sensitive   = true
  description = "Access/secret ключи Terraform-аккаунта для S3-бэкенда"
}

output "cicd_service_account_id" {
  value       = yandex_iam_service_account.cicd.id
  description = "ID сервисного аккаунта CI/CD (пригодится, если решите использовать Workload Identity)"
}

output "cicd_service_account_keys" {
  value = {
    access_key = yandex_iam_service_account_static_access_key.cicd-sa-static-key.access_key
    secret_key = yandex_iam_service_account_static_access_key.cicd-sa-static-key.secret_key
  }
  sensitive   = true
  description = "Статические ключи CI/CD-аккаунта"
}

# JSON-ключ CI/CD-аккаунта целиком — его нужно положить в секрет GitHub YC_SA_KEY.
# Достать так:
#   terraform output -raw cicd_sa_json_key > ../../key.json
output "cicd_sa_json_key" {
  value = jsonencode({
    id                 = yandex_iam_service_account_key.cicd-sa-json-key.id
    service_account_id = yandex_iam_service_account_key.cicd-sa-json-key.service_account_id
    created_at         = yandex_iam_service_account_key.cicd-sa-json-key.created_at
    key_algorithm      = yandex_iam_service_account_key.cicd-sa-json-key.key_algorithm
    public_key         = yandex_iam_service_account_key.cicd-sa-json-key.public_key
    private_key        = yandex_iam_service_account_key.cicd-sa-json-key.private_key
  })
  sensitive   = true
  description = "Готовый JSON-ключ CI/CD-аккаунта для секрета GitHub YC_SA_KEY"
}
