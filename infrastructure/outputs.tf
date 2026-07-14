output "network_id" {
  value       = yandex_vpc_network.main.id
  description = "ID созданной VPC-сети"
}

output "subnet_ids" {
  value = {
    "ru-central1-a" = yandex_vpc_subnet.subnet_a.id
    "ru-central1-b" = yandex_vpc_subnet.subnet_b.id
    "ru-central1-d" = yandex_vpc_subnet.subnet_d.id
  }
  description = "Карта ID подсетей по зонам доступности"
}

# Публичные и приватные IP нод — понадобятся для inventory Kubespray.
output "k8s_nodes_ips" {
  value = {
    for name, instance in yandex_compute_instance.k8s_nodes :
    name => {
      public_ip  = instance.network_interface.0.nat_ip_address
      private_ip = instance.network_interface.0.ip_address
    }
  }
  description = "Публичные и приватные IP-адреса нод кластера"
}

output "container_registry_id" {
  value       = yandex_container_registry.this.id
  description = "ID Container Registry (положить в секрет GitHub YC_REGISTRY_ID)"
}

output "container_registry_url" {
  value       = "cr.yandex/${yandex_container_registry.this.id}"
  description = "Полный адрес Container Registry"
}
