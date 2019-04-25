[![Build Status](https://travis-ci.com/otus-devops-2019-02/Tennki_infra.svg?branch=master)](https://travis-ci.org/otus-devops-2019-02/Tennki_infra)

# Tennki_infra
Tennki Infra repository

# IP
bastion_IP = 35.207.181.156
someinternalhost_IP = 10.156.0.3

# Для подключения к someinternalhost в одну команду можно выполнить:
ssh -A 35.207.181.156 -t 'ssh 10.156.0.3'

# Для подключения к someinternalhost командой 'ssh  someinternalhost' можно прописать в ssh_config файл следующий конфиг:
Host bastion
    Hostname 35.207.181.156
    ForwardAgent yes

Host someinternalhost
    Hostname 10.156.0.3
    Port 22
    ProxyCommand ssh -q -W %h:%p bastion



testapp_IP = 35.242.220.7
testapp_port = 9292

# Запауск инстанса c приложением с использованием startup script хранящимся локально
gcloud compute instances create reddit-app-auto\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags my-puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=startup_script.sh

# Запауск инстанса приложения с использованием startup script хранящимся в бакете
gcloud compute instances create reddit-app-auto-url\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags my-puma-server \
  --restart-on-failure \
  --metadata startup-script-url=gs://tennki-sh-bucket/startup_script.sh


# Создание бакета
gsutil mb -l europe-west3  gs://tennki-sh-bucket/
# Копирование данных в бакет
gsutil cp startup_script.sh gs://tennki-sh-bucket


# Создание правила брандмауэра
gcloud compute firewall-rules create my-puma-server \
    --network default \
    --action allow \
    --direction ingress \
    --rules tcp:9292 \
    --source-ranges 0.0.0.0/0 \
    --priority 1000 \
    --target-tags my-puma-server


# Terraform 1
- При применении конфигурации, внесенные вручную ssh ключи перезаписываются, сохраняются только указанные в конфигурационном файле.
- Конфигурация балансировщика в файле lb.tf Использована сross-region балансировка.
Сделано через global forward rule с привязкой глобального статического ip. 
Отсутсвтует атомасштабирование. Количество инстансов задается через переменную worker_count. Созданные инстансы автоматически добавляются в инстанс-группу. 
Можно убрать у инстансов внешние ip т.к. трафик идет через балансировщик. 

- Ручное управление количеством инстансов через параметр count: 

variable worker_count {
  description = "Number of workers"
  default     = "1"
}

resource "google_compute_instance" "app-pool" {
  count        = "${var.worker_count}"
  name         = "reddit-app-${count.index}"
  machine_type = "g1-small"
  zone         = "${var.zone}"
  tags         = ["reddit-app"]
  boot_disk {
    initialize_params {
      image = "reddit-full"
    }
  }
  network_interface {    
    network = "default"    
    access_config {}
  }  
}

Недостаток, в ручном задании количества инстансов.

# Terraform 2
- Хранение стейтов вынесено в бакет. Для prod и stage указаны разные префиксы. При одновременном запуске изменений ресурсов происходит блокировка стейтфайла.
------
  backend "gcs" {
    bucket = "tennki-storage-bucket"
    prefix = "prod"
  }
------
  backend "gcs" {
    bucket = "tennki-storage-bucket"
    prefix = "stage"
  }

- Добавлена переменная env, которая передается в модули и подставляется в имена инстансов и теги., т.е. можно одновременно развернуть stage и prod. Только дополнительно надо добавить env в имена других ресурсов, чтобы они не дублировались. 

- Организовано включение/выключение провиженеров через переменную enable_provisoners, которая передается в модули. При отключении провиженеров, в них поставляются команды/скрипты, которые ничего не выполняю. Варианты сделаны как элементы списка, а переменная enable_provisoners позволяет выбрать тот или иной вариант через функцию element.
  ---app module---
  provisioner "file" {
    source      = "${element(list("${path.module}/files/null.sh","${path.module}/files/puma.service"),var.enable_provisioners)}"
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    inline = ["${element(list("echo","sudo sed -i '/ExecStart/iEnvironment=\"DATABASE_URL=${var.db_url}\"' /tmp/puma.service"),var.enable_provisioners)}"]
  }
  provisioner "remote-exec" {
    script = "${element(list("${path.module}/files/null.sh","${path.module}/files/deploy.sh"),var.enable_provisioners)}"
  }
  
  - Чтобы mongo стала доступна на внутреннем ip, через провиженер меняем конфиг и перезапускам сервис.
  ---db module---
  provisioner "remote-exec" {
    inline = [
      "${element(list("echo","sudo sed -i '/bindIp/s/^/#/g' /etc/mongod.conf"),var.enable_provisioners)}",
      "${element(list("echo","sudo systemctl restart mongod.service"),var.enable_provisioners)}",
    ]
  }
  ------

- При развертывании получаем аутпут переменную db_url с внутренним адресом БД инстанса и передаем ее в инстанс с приложением. Прописываем в переменные юнита.
  ------
  provisioner "remote-exec" {
    inline = ["${element(list("echo","sudo sed -i '/ExecStart/iEnvironment=\"DATABASE_URL=${var.db_url}\"' /tmp/puma.service"),var.enable_provisioners)}"]
  }
  ------

- Правило фаервола firewall_mongo можно не создавать. Т.к. трафик идет по внутренней сети гугла и тесты показали, что никакого влияния на прохождение трафика нет. Протестировано для разных зон в одном регионе и для разных регионов. 

# Ansible-1
- При удалении директории reddit ansible видит, что необходимо привести систему в нужно состояние и клонирует репозиторий. Если директория есть, то ansible ничего не меняет.
- Файл inventory.py генерируте инвентори используя google-api-python-client, код которого находится в папке ansible/lib. Для работы скрипта необходимо указать ИД проекта и зону в файле inventory.ini (пример конфигурации указан в inventory.ini.example). В файле inventory.json приведен результат работы скрипта. 
Примерное содержание inventory.json:
{
   "_meta": {
       "hostvars": {
           <instance-name>: {
               "ansible_host": <external ip>, 
               "ansible_user": <user>, 
               "tags": [<tags>]
           }           
       }
   }, 
   "app": {
       "hosts": [
           <app-instance-name>
       ]
   }, 
   "db": {
       "hosts": [
           <db-instance-name>
       ]
   }
}
- Для проверки "ansible-playbook --syntax-check clone.yml" со стороны Тревиса добавлен вывод "пустого" инвентари т.к. у тревиса нет доступа к проекту и получить реальный список инсансов невозможно.  
{
    "app": {
        "hosts": [
            "appserver"
        ]
    }, 
    "db": {
        "hosts": [
            "dbserver"
        ]
    }
}
- Скрипт проверяет, есть ли в директории ini файл с информацией о проекте. Если его, нет то генерится "пустой" инвентари. Но скрипт не проверят коректность указанных данных в ini файле т.е. если такого проекта не существует или не удается получить доступ к проекту, то скрипт не отработает.

# Ansible-2
- Протестированы различные подходы к написанию плейбуков, использование тегов и хэндлеров. 
- Переделаны провиженеры для пакера. Замена скриптов установки на модули ансибл. 
- Дописан скрипт для динамического инвентари. Теперь в hostvars помимо внешних ip добавляются внутренние ip инстансов и в плейбуке конфигурирования приложения (app.yml) подставляется внутренний ip db-хоста.
vars:
    db_host: "{{ groups['db'] | map('extract', hostvars, 'int_ip') | list | join('\n') }}"

# Ansible-3
- Созданы роли app и db, добавлена коммьюнити роль nginx.
- Протестирована работа с разными окружениями с использованием ролей.
- Протестирована работа с ansible vault
- Дописан скрипт для динамического инвентари для возможности использования с неколькими окружениями. ini-файл (inventory.ini.example) с настройками лежит в директории окружения. Дополнительный библиотеки вынесены в ansible/lib и совместно используются скриптами из разных окружений
- Написаны скрипты для тестирования run-test.sh, tests.sh и добавлены в travis.
  run-test.sh - запускает докер контейнер, в котором будут запускаться тесты и запускает скрипт с тестами (tests.sh)
  tests.sh - описаны сами "тесты". 
    - Проверка шаблонов пакера
    - Проверка terraform validate и tflint для окружений prod и stage
    - Проверка ansible-lint для playbook-ов
    - Проверка наличия build status-а в README.md

# Ansible-4
- Для настройки nginx используется файл nginx.yml, который передается как extra_var для группы "app"
переменная deploy_user также перенесена в файл nginx.yml т.к. последний extra_var переопределяет все предыдущие и нет возможности одновременно указать путь до файла и хэш.
- Добавлен тест для проверки слушает ли MongoDB порт tcp://0.0.0.0:27017. Использован модуль testinfra socket.
