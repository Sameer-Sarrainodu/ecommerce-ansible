#!/bin/bash

set -e

echo "🚀 Installing Ansible collections..."

ansible-galaxy collection install -r collections/requirements.yml

echo "🚀 Starting ecommerce deployment..."

ansible-playbook playbooks/site.yml