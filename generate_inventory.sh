#!/bin/bash

# Hämta IP-adresser från Terraform-output och ta bort dubbelfnuttar och kommatecken
server_ips=$(terraform output server_ips | tr -d '",[]')

# Skapa Ansible-inventory-filen
echo "[web_servers]" > inventory.ini
for ip in $server_ips; do
  echo $ip >> inventory.ini
done

# Lägg till övriga inställningar
echo -e "\n[all:vars]" >> inventory.ini
echo "ansible_ssh_private_key_file=/home/sandung/ms-key.pem" >> inventory.ini
echo "ansible_user=ubuntu" >> inventory.ini
