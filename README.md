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


