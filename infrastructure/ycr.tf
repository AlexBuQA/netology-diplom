resource "yandex_container_registry" "this" {
  name = var.ycr_name
}

# Разрешаем анонимный pull образов (viewer для всех).
# Это упрощает демонстрацию: kubelet сможет тянуть образ без imagePullSecret.
# В реальном проде так делать не стоит, но для дипломной демонстрации допустимо.
resource "yandex_container_registry_iam_binding" "public_access" {
  registry_id = yandex_container_registry.this.id
  role        = "container-registry.images.puller"

  members = [
    "system:allUsers"
  ]
}
