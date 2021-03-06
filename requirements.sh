#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Ensure that APT works with HTTPS..."
sudo apt-get -qq update -y
sudo apt-get -qq install -y \
  apt-transport-https \
  ca-certificates \
  software-properties-common \
  curl

echo "Add Kubernetes repo..."
sudo sh -c 'curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -'
sudo sh -c 'echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'

echo "Add Docker repo..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"


echo "Add GlusterFS repo..."
sudo add-apt-repository -y ppa:gluster/glusterfs-3.12

echo "Updating Ubuntu..."
sudo apt-get -qq update -y
sudo DEBIAN_FRONTEND=noninteractive \
  apt-get -y -qq \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  upgrade

echo "Installing Kubernetes requirements..."
sudo apt-get -qq install -y \
  docker-ce=18.03.1~ce-0~ubuntu \
  kubernetes-cni=0.6.0-00 \
  kubeadm=1.10.9-00 \
  kubelet=1.10.9-00 \
  kubectl=1.10.9-00 \


echo "Installing other requirements..."
# APT requirements
sudo apt-get -qq install -y \
  python \
  daemon \
  attr \
  glusterfs-client \
  nfs-common \
  jq

# Helm
HELM_TGZ=helm-v2.10.0-linux-amd64.tar.gz
wget -P /tmp/ https://kubernetes-helm.storage.googleapis.com/$HELM_TGZ
tar -xf /tmp/$HELM_TGZ -C /tmp/
sudo mv /tmp/linux-amd64/helm /usr/local/bin/

# Heketi
HEKETI_TGZ=heketi-client-v5.0.0.linux.amd64.tar.gz
wget -P /tmp/ https://github.com/heketi/heketi/releases/download/v5.0.0/$HEKETI_TGZ
tar -xf /tmp/$HEKETI_TGZ -C /tmp/
sudo mv /tmp/heketi-client/bin/heketi-cli /usr/local/bin/
sudo chmod 0755 /usr/local/bin/heketi-cli
rm -R /tmp/heketi-client/

echo "Pulling required Docker images..."
# Essential Kubernetes containers are listed in following files:
# https://github.com/kubernetes/kubernetes/blob/master/cmd/kubeadm/app/constants/constants.go (etcd-version)
# https://github.com/kubernetes/kubernetes/blob/master/cluster/addons/dns/kubedns-controller.yaml.base (kube-dns-version)
kube_version="v1.10.9"
kube_dns_version="1.14.10"
etcd_version="3.1.12"
flannel_version="v0.10.0"
sudo docker pull gcr.io/google_containers/kube-apiserver-amd64:$kube_version
sudo docker pull gcr.io/google_containers/kube-proxy-amd64:$kube_version
sudo docker pull gcr.io/google_containers/kube-controller-manager-amd64:$kube_version
sudo docker pull gcr.io/google_containers/kube-scheduler-amd64:$kube_version
sudo docker pull gcr.io/google_containers/etcd-amd64:$etcd_version
sudo docker pull gcr.io/google_containers/pause-amd64:3.0
sudo docker pull gcr.io/google_containers/k8s-dns-sidecar-amd64:$kube_dns_version
sudo docker pull gcr.io/google_containers/k8s-dns-kube-dns-amd64:$kube_dns_version
sudo docker pull gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:$kube_dns_version
sudo docker pull quay.io/coreos/flannel:$flannel_version-amd64

# After having installed all the necessary packages, we check whether there are related security-updates
sudo apt-get -qq update -y && sudo unattended-upgrades -d
