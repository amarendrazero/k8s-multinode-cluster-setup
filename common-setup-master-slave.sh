#!/bin/bash

#Disabling Swap and Installing Dependencies
swapoff -a
dnf install -y iproute-tc

#Loading Kernel Modules
modprobe overlay
modprobe br_netfilter

#Configuring Kernel Modules to Load at Boot
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

#Configuring System Settings
#Configuring System Settings
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

#Disabling SELinux Enforcing Mode
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

#Defining Variables and Creating YUM Repositories
KUBERNETES_VERSION=v1.29
PROJECT_PATH=prerelease:/main

cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/repodata/repomd.xml.key
EOF


cat <<EOF | tee /etc/yum.repos.d/cri-o.repo
[cri-o]
name=CRI-O
baseurl=https://pkgs.k8s.io/addons:/cri-o:/$PROJECT_PATH/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/addons:/cri-o:/$PROJECT_PATH/rpm/repodata/repomd.xml.key
EOF

#Installing Kubernetes and CRI-O
dnf install -y cri-o kubelet kubeadm kubectl

#Enabling and Starting Services
systemctl enable --now crio

systemctl enable --now kubelet
