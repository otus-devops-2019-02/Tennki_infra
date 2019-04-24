#!/bin/bash
# Создание пустых файлов ключей для тестов
touch ~/.ssh/appuser.pub ~/.ssh/appuser
# Проверка packer в зависимости от результата вывод должен быть зеленый или красный
echo -e "\e[93m-=Validate Packer Templates=-\e[0m"
for f in packer/*.json; do 
echo -e "\e[93m---Validate $f---\e[0m"
result="$(packer validate --var-file=packer/variables.json.example $f)"
if grep -q "success" <<< $result; then 
echo -e "\e[92m$result\e[0m"
else
echo -e "\e[91m$result\e[0m"
fi
echo
done
# Проверка terraform validate для prod
echo
echo -e "\e[93m-=Validate Terraform Prod Evironment=-\e[0m"
cd terraform/prod
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
if (terraform validate); then 
echo -e "\e[92mValidation - Success\e[0m"
fi
# Проверка tflint для prod
echo
echo -e "\e[93m-=TFlint Prod Evironment=-\e[0m" 
tflint
# Проверка terraform validate для stage
echo
echo -e "\e[93m-=Validate Terraform Stage Evironment=-\e[0m"
cd ../stage
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
if (terraform validate); then 
echo -e "\e[92mValidation - Success\e[0m"
fi
# Проверка tflint для stage
echo
echo -e "\e[93m-=TFlint Prod Evironment=-\e[0m"
tflint
# Проверка ansible lint
echo
cd ../..
echo -e "\e[93m-=Ansible lint validation=-\e[0m"
if (ansible-lint ansible/playbooks/*.yml); then 
echo -e "\e[92mValidation - Success\e[0m"
fi
# Проверка build badge
echo
echo -e "\e[93m-=Build status validation=-\e[0m"
if grep -q "[Build Status]" README.md; then 
echo -e "\e[92mBuild status exists\e[0m"
else
echo -e "\e[91mBuild status does not exist\e[0m"
fi
