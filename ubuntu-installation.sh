#!/bin/bash
# Copyright 2022 Intelius AI
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script needs to run as the root user.

# There are two command line arguments (both optional) but quite important to understand
# $1 is the KUBERNETES VERSION
# $2 is the USER for whom to install this.

DEFAULTKUBERNETESVERSION="1.21"
date
echo "Starting Intelius AI Kubernetes Installation Microk8s installation script"
if [ ! -z $1 ] 
then 
    export KUBEVERSION=$1
else
    export KUBEVERSION=$DEFAULTKUBERNETESVERSION
fi

echo "Installing Kubernetes version " $KUBEVERSION

if [ ! -z $2 ] 
then 
    export INSTALLUSER=$2
else
    export INSTALLUSER=$(ls /home/* -d | head -n 1 | cut -d/ -f3)
fi
echo "Targeting user $INSTALLUSER for Microk8s installation"
export DEBIAN_FRONTEND=noninteractive

# Patch and update the VM 
sudo apt update -y && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt clean -y &&  sudo apt autoclean -y

# Install few tools 
sudo apt-get install -y fail2ban vim
sudo apt-get install unzip

# Install Microk8s and support tools 
sudo snap install microk8s --classic --channel=1.21/stable
sudo snap install --stable docker
sudo snap install kubectl --classic --channel=1.21/stable
sudo snap install helm --classic 
sleep 60 # Sometimes microk8s needs time to stabilize

cd /tmp
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && sudo install skaffold /usr/local/bin/
export PATH=$PATH:/snap/bin


# Install k9s for debugging (optional)
sudo wget https://github.com/derailed/k9s/releases/download/v0.24.1/k9s_Linux_x86_64.tar.gz -O /tmp/k9s.tar.gz
tar -xvzf /tmp/k9s.tar.gz -C /tmp
sudo mv /tmp/k9s /usr/local/bin
sudo mkdir -p /home/$USER/.kube
sudo microk8s config > sudo /root/.kube/config # Will need this for installing application
sudo chown -R $USER:$USER /home/$USER/.kube/
sudo microk8s config > /home/$USER/.kube/config
sudo usermod -a -G microk8s $USER
sudo chmod 600 /home/$USER/.kube/config


sudo microk8s.enable rbac
sudo microk8s.enable dns
sudo microk8s.enable storage
sudo microk8s.enable registry
sudo microk8s.enable ingress
kubectl get all --all-namespaces # Debug output
sleep 60 # Sometimes these plugins need a little time to stabilize


echo "Printing kubeconfig (don't do this in production)"
sudo microk8s inspect
sudo microk8s config
echo "Done installing microk8s"