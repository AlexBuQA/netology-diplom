# Дипломный практикум в Yandex.Cloud — `Александра Бужор`

  * [Цели](#цели)
  * [Результаты работы — репозитории и ссылки](#результаты-работы--репозитории-и-ссылки)
  * [Предварительные требования](#предварительные-требования)
  * [Этапы выполнения](#этапы-выполнения)
    * [1. Создание облачной инфраструктуры](#1-создание-облачной-инфраструктуры)
    * [2. Создание Kubernetes-кластера](#2-создание-kubernetes-кластера)
    * [3. Создание тестового приложения](#3-создание-тестового-приложения)
    * [4. Мониторинг и деплой приложения](#4-мониторинг-и-деплой-приложения)
    * [5. Деплой инфраструктуры в Terraform pipeline (Atlantis)](#5-деплой-инфраструктуры-в-terraform-pipeline-atlantis)
    * [6. Установка и настройка CI/CD](#6-установка-и-настройка-cicd)
  * [Что необходимо для сдачи задания](#что-необходимо-для-сдачи-задания)

---

## Цели

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes-кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---

## Результаты работы — репозитории и ссылки

- Репозиторий с инфраструктурой (этот репозиторий): `https://github.com/AlexBuQA/netology-diplom`
- Репозиторий тестового приложения: `https://github.com/AlexBuQA/test-nginx-app`
- Собранный Docker-образ: `cr.yandex/<REGISTRY_ID>/test-nginx-app:latest`
- Тестовое приложение: `http://<NODE_PUBLIC_IP>/app`
- Grafana: `http://<NODE_PUBLIC_IP>/` — логин `admin`, пароль `prom-operator`
- Пример pull request с комментариями Atlantis: `https://github.com/AlexBuQA/netology-diplom/pull/
- Пайплайны CI/CD: `https://github.com/AlexBuQA/test-nginx-app/actions`

---

## Предварительные требования

На рабочей машине должны быть установлены:

- [Yandex Cloud CLI (`yc`)](https://yandex.cloud/ru/docs/cli/quickstart) и выполнен `yc init`;
- [Terraform](https://developer.hashicorp.com/terraform/downloads) версии **>= 1.6** (не старше 1.5.x по требованию задания);
- `kubectl`, `helm`, `git`, `jq`;
- Python 3.10+ и `pip` (для Kubespray);
- Сгенерированная SSH-пара:

```bash
ssh-keygen -t ed25519 -C "abuzhor" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub   # это значение пойдёт в переменную ssh_public_key
```

IAM-токен для Terraform получаем командой (действует 12 часов):

```bash
yc iam create-token
```

Структура репозитория (содержимое папки — это корень репозитория `netology-diplom`):

```
.
├── service-account/     # этап 0: сервисные аккаунты Terraform и CI/CD
├── backend/             # этап 1: S3-бакет для хранения state
├── infrastructure/      # этап 2: VPC, ВМ, Container Registry
├── kubespray/           # inventory и заметки для Kubespray
├── k8s-configs/         # манифесты приложения и ingress
├── atlantis/            # деплой Atlantis в кластер
├── atlantis.yaml        # репозиторный конфиг Atlantis
└── README.md
```

---

## Этапы выполнения

### 1. Создание облачной инфраструктуры

**Задание.** Подготовить облачную инфраструктуру при помощи Terraform: создать сервисный
аккаунт с достаточными (но не избыточными) правами, подготовить S3-backend для хранения
state, создать VPC с подсетями в разных зонах доступности. Команды `terraform apply` и
`terraform destroy` должны выполняться без ручных действий.

#### Решение

**Шаг 1. Сервисные аккаунты** (папка [`service-account`](./service-account)).

Создаём два сервисных аккаунта: `tf-sa-diplom` с ролью `editor` (для Terraform) и
`cicd-sa-diplom` с ролями `container-registry.images.pusher/puller` (для CI/CD).
Права суперпользователя намеренно не используются.

```bash
cd service-account
cp terraform.tfvars.example terraform.tfvars
# впишите yc_token, yc_cloud_id, yc_folder_id
terraform init
terraform apply
```

Ключи Terraform-аккаунта выводятся как sensitive-данные, достаём их так:

```bash
terraform output -json service_account_keys | jq -r '.access_key'
terraform output -json service_account_keys | jq -r '.secret_key'
```

Эти `access_key` и `secret_key` понадобятся дальше в файлах `terraform.tfvars` и `backend.hcl`.

> 📸 **Скриншот:** список сервисных аккаунтов в консоли Yandex Cloud (`tf-sa-diplom`, `cicd-sa-diplom`).

**Шаг 2. S3-бакет для state** (папка [`backend`](./backend)).

```bash
cd ../backend
cp terraform.tfvars.example terraform.tfvars
# впишите yc_token, yc_cloud_id, yc_folder_id, sa_access_key, sa_secret_key (из шага 1)
terraform init
terraform apply
```

Будет создан бакет `abuzhor-diplom-tfstate` с включённым версионированием.

> 📸 **Скриншот:** созданный бакет в разделе Object Storage.

**Шаг 3. Основная инфраструктура** (папка [`infrastructure`](./infrastructure)).

Здесь описаны: подключение S3-бэкенда ([`main.tf`](./infrastructure/main.tf)),
VPC с тремя подсетями в зонах `ru-central1-a/b/d` ([`vpc.tf`](./infrastructure/vpc.tf)),
а также ВМ и реестр (следующий этап).

Так как в блоке `backend "s3"` нельзя использовать переменные, ключи доступа
передаём через `backend.hcl`:

```bash
cd ../infrastructure
cp terraform.tfvars.example terraform.tfvars   # yc-креды + ssh_public_key
cp backend.hcl.example backend.hcl             # access_key/secret_key аккаунта tf-sa-diplom
terraform init -backend-config=backend.hcl
terraform apply
```

После применения `terraform.tfstate` появится в бакете, а подсети — в трёх зонах.

> 📸 **Скриншот:** файл `terraform.tfstate` в бакете.
> 📸 **Скриншот:** три подсети в разных зонах доступности.

---

### 2. Создание Kubernetes-кластера

**Задание.** Создать работоспособный Kubernetes-кластер на подготовленной инфраструктуре
(минимум 3 ВМ), обеспечить доступ из интернета. В `~/.kube/config` должны быть данные
доступа, команда `kubectl get pods --all-namespaces` должна отрабатывать без ошибок.

#### Решение

**Шаг 1. Виртуальные машины.** Описаны в [`infrastructure/k8s-nodes.tf`](./infrastructure/k8s-nodes.tf):
одна нода-мастер (`ru-central1-a`, обычная ВМ) и две ноды-воркера (`ru-central1-b`, `ru-central1-d`,
прерываемые для экономии). Образ Ubuntu 22.04 берётся автоматически через data-source
(это надёжнее хардкода `image_id`). ВМ создаются тем же `terraform apply`, что и на этапе 1.

Получаем IP-адреса нод:

```bash
terraform output k8s_nodes_ips
```

> 📸 **Скриншот:** три созданные ВМ в разделе Compute Cloud.

**Шаг 2. Разворачиваем кластер через Kubespray.**

```bash
git clone https://github.com/kubernetes-sigs/kubespray
cd kubespray
git checkout v2.28.0          # проверенная связка: Kubespray v2.28.0 → Kubernetes v1.32.5
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

cp -rfp inventory/sample inventory/mycluster
```

Теперь:
1. Замените `inventory/mycluster/inventory.ini` содержимым нашего файла
   [`kubespray/inventory.ini`](./kubespray/inventory.ini), подставив реальные
   публичные и приватные IP из `terraform output k8s_nodes_ips`.
2. В `inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml` добавьте внешний IP мастера
   в сертификат API:
   ```yaml
   supplementary_addresses_in_ssl_keys:
     - "PUBLIC_IP_MASTER"
   ```
   Подробности — в [`kubespray/README-kubespray.md`](./kubespray/README-kubespray.md).

Запускаем деплой (ключ SSH и отключение проверки host key):

```bash
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml \
  -b -v -u ubuntu --private-key ~/.ssh/id_ed25519
```

> 📸 **Скриншот:** успешное завершение playbook (`PLAY RECAP` без failed).

**Шаг 3. Забираем kubeconfig и проверяем доступ.**

```bash
ssh ubuntu@<MASTER_PUBLIC_IP> "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/config
# заменяем внутренний адрес на внешний IP мастера
sed -i 's#https://127.0.0.1:6443#https://<MASTER_PUBLIC_IP>:6443#' ~/.kube/config
chmod 600 ~/.kube/config

kubectl get nodes
kubectl get pods --all-namespaces
```

Все ноды должны быть в статусе `Ready`, а поды — `Running`.

> 📸 **Скриншот:** вывод `kubectl get nodes` и `kubectl get pods --all-namespaces`.

---

### 3. Создание тестового приложения

**Задание.** Подготовить простое приложение (nginx, отдающий статическую страницу),
Dockerfile и реестр с собранным образом.

#### Решение

**Шаг 1. Container Registry** описан в [`infrastructure/ycr.tf`](./infrastructure/ycr.tf)
и создаётся тем же `terraform apply`. Получаем его ID:

```bash
terraform output container_registry_id
```

**Шаг 2. Репозиторий приложения** [`test-nginx-app`](https://github.com/AlexBuQA/test-nginx-app)
содержит `Dockerfile`, `index.html`, `nginx.conf` и workflow-файлы GitHub Actions.
Образ соберётся автоматически при первом же push в `main` (см. этап 6), после чего
появится в реестре с тегом `latest`.

> 📸 **Скриншот:** собранный образ `test-nginx-app` в Container Registry.

---

### 4. Мониторинг и деплой приложения

**Задание.** Задеплоить в кластер Prometheus, Grafana, Alertmanager и node_exporter,
а также тестовое приложение. Обеспечить HTTP-доступ на 80 порту к Grafana и к приложению.

#### Решение

**Шаг 1. Мониторинг** — ставим `kube-prometheus-stack` (включает Prometheus, Grafana,
Alertmanager, node_exporter и операторы):

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace

kubectl get pods -n monitoring
```

> 📸 **Скриншот:** все поды в namespace `monitoring` в статусе `Running`.

**Шаг 2. Тестовое приложение.** Манифесты лежат в [`k8s-configs/`](./k8s-configs).
Файл `deployment.yaml` генерируется Terraform из шаблона
[`templates/deployment.yaml.tmpl`](./k8s-configs/templates/deployment.yaml.tmpl)
с автоматической подстановкой адреса реестра.

```bash
kubectl apply -f k8s-configs/namespace.yaml
kubectl apply -f k8s-configs/deployment.yaml
kubectl apply -f k8s-configs/service.yaml
kubectl get pods -n abuzhor-nginx
```

**Шаг 3. Ingress.** Чтобы и Grafana, и приложение работали на одном 80 порту,
ставим ingress-nginx контроллер с `hostNetwork`:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install my-nginx-ingress-controller ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.hostNetwork=true \
  --set controller.service.enabled=false

kubectl apply -f k8s-configs/app-ingress.yaml
kubectl apply -f k8s-configs/grafana-ingress.yaml
```

Узнаём, на какой ноде поднялся ingress-контроллер, и берём её публичный IP:

```bash
kubectl get pods -n ingress-nginx -o wide
```

Проверяем:
- Grafana — `http://89.169.187.246/` (логин `admin`, пароль `prom-operator`);
- Приложение — `http://89.169.187.246/app`.

> 📸 **Скриншот:** Grafana с дашбордами по состоянию кластера.
> 📸 **Скриншот:** открытая страница приложения по адресу `/app`.

---

### 5. Деплой инфраструктуры в Terraform pipeline (Atlantis)

**Задание.** Задеплоить Atlantis в кластер для отслеживания изменений инфраструктуры
через pull request'ы.

#### Решение

**Шаг 1. Деплой Atlantis.** Из-за санкций `registry.terraform.io` недоступен из РФ,
поэтому в [`atlantis/atlantis.yaml`](./atlantis/atlantis.yaml) добавлен ConfigMap
с `.terraformrc`, перенаправляющий скачивание провайдеров на зеркало Yandex Cloud.

Заполняем секреты и применяем манифесты по порядку:

```bash
kubectl apply -f atlantis/atlantis-ns.yaml
cp atlantis/secrets.yaml.example atlantis/secrets.yaml
# заполните secrets.yaml: github-token, webhook-secret, yc-*, s3-*, ssh-public-key
kubectl apply -f atlantis/secrets.yaml
kubectl apply -f atlantis/atlantis.yaml

kubectl get pods -n atlantis
```

GitHub personal access token (classic) создаётся в Settings → Developer settings с scope `repo`.
Webhook-secret — случайная строка из 32 символов.

**Шаг 2. Webhook в GitHub.** В настройках репозитория `netology-diplom` →
Webhooks → Add webhook:
- Payload URL: `http://<NODE_PUBLIC_IP>:32001/events`
- Content type: `application/json`
- Secret: значение `webhook-secret`
- События: Pull requests, Pushes, Issue comments.

> 📸 **Скриншот:** настроенный webhook с зелёной галочкой (успешная доставка).

**Шаг 3. Проверка.** Репозиторный конфиг [`atlantis.yaml`](./atlantis.yaml) указывает
Atlantis на папку `infrastructure`. Создаём ветку, добавляем тестовый файл `test.tf`,
пушим, открываем pull request — Atlantis автоматически публикует `plan`. Командой
`atlantis apply` в комментарии применяем изменения.

> 📸 **Скриншот:** комментарий Atlantis с результатом `plan` в pull request.
> 📸 **Скриншот:** успешный `apply`.

---

### 6. Установка и настройка CI/CD

**Задание.** Настроить автоматическую сборку Docker-образа при коммите и автоматический
деплой при создании тега.

#### Решение

CI/CD реализован на **GitHub Actions**. В репозитории
[`test-nginx-app`](https://github.com/AlexBuQA/test-nginx-app) два workflow:

- [`build.yaml`](https://github.com/AlexBuQA/test-nginx-app/blob/main/.github/workflows/build.yaml) —
  при коммите в `main` собирает образ и пушит в реестр с тегами `latest` и `<sha>`;
- [`deploy.yaml`](https://github.com/AlexBuQA/test-nginx-app/blob/main/.github/workflows/deploy.yaml) —
  при создании тега `v*` собирает образ с версией и деплоит его в кластер.

Аутентификация в реестр — через `yc-actions/yc-cr-login@v3` по JSON-ключу
сервисного аккаунта `cicd-sa-diplom`.

**Шаг 1. Секреты репозитория** (Settings → Secrets and variables → Actions):

```bash
# JSON-ключ CI/CD-аккаунта -> секрет YC_SA_KEY
yc iam key create --service-account-name cicd-sa-diplom --output key.json
cat key.json   # содержимое целиком в секрет YC_SA_KEY

# ID реестра -> секрет YC_REGISTRY_ID  (из terraform output container_registry_id)

# kubeconfig в base64 -> секрет KUBE_CONFIG
base64 -w0 ~/.kube/config
```

| Секрет           | Значение                                            |
|------------------|-----------------------------------------------------|
| `YC_SA_KEY`      | содержимое `key.json`                               |
| `YC_REGISTRY_ID` | ID реестра (`crp...`)                               |
| `KUBE_CONFIG`    | kubeconfig в base64                                 |

**Шаг 2. Проверка CI.** Делаем коммит в `main` — workflow `build.yaml` отрабатывает,
в реестре появляется образ с тегом `latest`.

> 📸 **Скриншот:** зелёный workflow `build.yaml` и образ `:latest` в реестре.

**Шаг 3. Проверка CD.** Меняем номер версии в `index.html` (например, `v1.0` → `v1.1`),
коммитим, затем создаём тег:

```bash
git tag v1.1 -m "Release v1.1"
git push origin v1.1
```

Workflow `deploy.yaml` собирает образ `:v1.1`, пушит его и обновляет Deployment в кластере.

> 📸 **Скриншот:** workflow `deploy.yaml` отработал.
> 📸 **Скриншот:** образ `:v1.1` в реестре.
> 📸 **Скриншот:** поды используют новый образ (`kubectl -n abuzhor-nginx get pods` + `describe`).
> 📸 **Скриншот:** страница приложения показывает новую версию.

---

## Что необходимо для сдачи задания

1. ✅ Репозиторий с конфигурацией Terraform, готовность создать ресурсы с нуля.
2. ✅ Пример pull request с комментариями Atlantis (или скриншоты CI/CD-terraform pipeline).
3. ✅ Репозиторий с конфигурацией Ansible (Kubespray) — inventory в папке `kubespray`.
4. ✅ Репозиторий с Dockerfile тестового приложения и ссылка на собранный образ.
5. ✅ Репозиторий с конфигурацией Kubernetes-кластера (`k8s-configs`).
6. ✅ Ссылка на приложение и веб-интерфейс Grafana с данными доступа.
7. ✅ Все репозитории размещены на GitHub (`AlexBuQA`).

---

## Порядок удаления ресурсов

Чтобы не тратить облачный бюджет, после демонстрации удаляем всё в обратном порядке:

```bash
# 1. Инфраструктура (ВМ, сети, реестр)
cd infrastructure && terraform destroy

# 2. Бакет (сначала очистить, потом удалить)
cd ../backend && terraform destroy

# 3. Сервисные аккаунты
cd ../service-account && terraform destroy
```
