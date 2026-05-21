#!/bin/bash

set -e

echo "🚀 Installing Ansible collections..."

ansible-galaxy collection install -r collections/requirements.yml

echo "🚀 Configuring DB and Middleware Servers..."

ansible-playbook \
  -i inventories/dev/hosts.ini \
  playbooks/site.yml

echo "🚀 Initializing Packer..."

cd packer

packer init .

echo "🚀 Building Catalogue Image..."

packer build \
  -var-file=variables.pkrvars.hcl \
  catalogue.pkr.hcl

echo "✅ Catalogue image build completed successfully!"