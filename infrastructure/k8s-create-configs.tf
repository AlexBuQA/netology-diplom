# Автоматически генерируем k8s-configs/deployment.yaml из шаблона,
# подставляя реальный адрес нашего Container Registry.
#
# Важно: используем встроенную функцию templatefile() и провайдер hashicorp/local.
# Старый подход через data "template_file" (провайдер hashicorp/template) устарел
# и не работает на новых системах (например, Apple Silicon) — поэтому не используем его.
resource "local_file" "deployment_rendered" {
  content = templatefile("${path.module}/../k8s-configs/templates/deployment.yaml.tmpl", {
    REGISTRY = "cr.yandex/${yandex_container_registry.this.id}"
  })
  filename = "${path.module}/../k8s-configs/deployment.yaml"

  depends_on = [
    yandex_container_registry.this
  ]
}
