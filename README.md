# Tennki_infra
Tennki Infra repository

bastion_IP = 35.207.181.156
someinternalhost_IP = 10.156.0.3

#Для подключения к someinternalhost в одну команду можно выполнить:
ssh -A 35.207.181.156 -t 'ssh 10.156.0.3'

#Для подключения к someinternalhost командой 'ssh  someinternalhost' можно прописать в ssh_config файл следующий конфиг:
Host bastion
    Hostname 35.207.181.156
    ForwardAgent yes

Host someinternalhost
    Hostname 10.156.0.3
    Port 22
    ProxyCommand ssh -q -W %h:%p bastion



testapp_IP = 35.242.220.7
testapp_port = 9292

#Запауск инстанса c приложением с использованием startup script хранящимся локально
gcloud compute instances create reddit-app-auto\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags my-puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=startup_script.sh

##Запауск инстанса приложения с использованием startup script хранящимся в бакете
gcloud compute instances create reddit-app-auto-url\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags my-puma-server \
  --restart-on-failure \
  --metadata startup-script-url=gs://tennki-sh-bucket/startup_script.sh


#Создание бакета
gsutil mb -l europe-west3  gs://tennki-sh-bucket/
#Копирование данных в бакет
gsutil cp startup_script.sh gs://tennki-sh-bucket


#Создание правила брандмауэра
gcloud compute firewall-rules create my-puma-server \
    --network default \
    --action allow \
    --direction ingress \
    --rules tcp:9292 \
    --source-ranges 0.0.0.0/0 \
    --priority 1000 \
    --target-tags my-puma-server