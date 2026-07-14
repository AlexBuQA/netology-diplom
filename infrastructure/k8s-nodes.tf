# Берём актуальный образ Ubuntu 22.04 LTS автоматически.
# Это надёжнее, чем хардкодить image_id: тот со временем "протухает" и apply падает.
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "k8s_nodes" {
  for_each = {
    master1 = {
      zone          = "ru-central1-a"
      subnet_id     = yandex_vpc_subnet.subnet_a.id
      cores         = 2
      memory        = 4
      core_fraction = 100
    }
    worker1 = {
      zone          = "ru-central1-b"
      subnet_id     = yandex_vpc_subnet.subnet_b.id
      cores         = 2
      memory        = 4
      core_fraction = 100
    }
    worker2 = {
      zone          = "ru-central1-d"
      subnet_id     = yandex_vpc_subnet.subnet_d.id
      cores         = 2
      memory        = 4
      core_fraction = 100
    }
  }

  name        = "k8s-${each.key}"
  platform_id = "standard-v3"
  zone        = each.value.zone

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 30
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = each.value.subnet_id
    nat       = true # публичный IP, чтобы был доступ из интернета и к интернету
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }

  # Мастер — обычная (не прерываемая) ВМ, чтобы кластер был стабилен.
  # Воркеры — прерываемые (preemptible): дешевле, по заданию так и рекомендуется.
  scheduling_policy {
    preemptible = each.key != "master1"
  }
}
