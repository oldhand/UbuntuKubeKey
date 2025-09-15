#!/bin/bash


sudo kubeadm reset --force
# 移除 kubelet 工作目录
sudo rm -rf /var/lib/kubelet

# 移除 etcd 数据目录（控制平面节点）
sudo rm -rf /var/lib/etcd

# 移除 Kubernetes 配置残留
sudo rm -rf /etc/kubernetes

rm -rf /root/.kube/config

# 停止并删除所有 Kubernetes 相关容器
sudo docker rm -f $(sudo docker ps -q --filter name=k8s_) 2>/dev/null
# 删除 Kubernetes 相关镜像（谨慎操作，会删除所有 k8s 镜像）
sudo docker rmi $(sudo docker images -q --filter reference='k8s.gcr.io/*') 2>/dev/null
sudo docker rmi $(sudo docker images -q --filter reference='registry.aliyuncs.com/google_containers/*') 2>/dev/null
