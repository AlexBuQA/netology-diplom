# Настройка Kubespray

После клонирования Kubespray нужно сделать 3 вещи.

## 1. Скопировать inventory

```bash
cp -rfp inventory/sample inventory/mycluster
```

Затем заменить `inventory/mycluster/inventory.ini` на наш файл `inventory.ini`
(подставив реальные публичные и приватные IP из `terraform output k8s_nodes_ips`).

## 2. Разрешить внешний IP мастера в сертификате API

В файле `inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml` найти
и раскомментировать/добавить параметр (подставить ПУБЛИЧНЫЙ IP мастера):

```yaml
supplementary_addresses_in_ssl_keys:
  - "PUBLIC_IP_MASTER"
```

Без этого kubectl с локальной машины будет ругаться на сертификат,
т.к. в нём не будет внешнего адреса мастера.

## 3. (Опционально) Зафиксировать версию Kubernetes

Рекомендуется НЕ переопределять версию, а использовать ту, что идёт по умолчанию
с выбранным тегом Kubespray — так не будет проблем с контрольными суммами.

Проверенная связка: **Kubespray v2.28.0 → Kubernetes v1.32.5**.

Если всё же нужно задать версию явно, в том же `k8s-cluster.yml`:

```yaml
kube_version: v1.32.5
```
