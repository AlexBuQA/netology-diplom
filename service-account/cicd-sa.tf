# Отдельный сервисный аккаунт для CI/CD (GitHub Actions).
# Права строго минимальные: пушить и пуллить образы в Container Registry.
resource "yandex_iam_service_account" "cicd" {
  name        = "cicd-sa-diplom"
  description = "Service account for CI/CD (GitHub Actions)"
}

resource "yandex_resourcemanager_folder_iam_binding" "pusher" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.pusher"
  members = [
    "serviceAccount:${yandex_iam_service_account.cicd.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "puller" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.puller"
  members = [
    "serviceAccount:${yandex_iam_service_account.cicd.id}"
  ]
}

# Статический ключ для CI/CD (на случай, если понадобится).
resource "yandex_iam_service_account_static_access_key" "cicd-sa-static-key" {
  service_account_id = yandex_iam_service_account.cicd.id
  description        = "Static access key for CI/CD"
}

# Авторизованный (JSON) ключ для CI/CD — именно его мы положим в секрет GitHub YC_SA_KEY.
resource "yandex_iam_service_account_key" "cicd-sa-json-key" {
  service_account_id = yandex_iam_service_account.cicd.id
  description        = "Authorized (JSON) key for GitHub Actions login to Container Registry"
}
