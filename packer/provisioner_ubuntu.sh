#!/bin/bash
set -eux

sudo apt-get update -y
sudo apt-get install -y curl cloud-init

sudo curl "$nodeadm_link" -o /usr/local/bin/nodeadm 
sudo chmod +x /usr/local/bin/nodeadm
sudo /usr/local/bin/nodeadm install "$k8s_version" --credential-provider "$credential_provider"

sudo truncate -s 0 /etc/machine-id /var/lib/dbus/machine-id

sudo cloud-init clean
