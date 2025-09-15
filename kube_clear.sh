#!/bin/bash

# 检查是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：此脚本需要以 root 权限运行，请使用 sudo 执行"
    exit 1
fi

# 停止并禁用 openvswitch 服务（避免 kube-ovn 依赖的服务残留）
echo "停止并禁用 openvswitch 服务..."
sudo systemctl stop openvswitch-switch 2>/dev/null
sudo systemctl disable openvswitch-switch 2>/dev/null

# 清理 kube-ovn 相关的 CNI 配置（关键步骤，避免 reset 时调用残留插件）
echo "清理 CNI 配置文件..."
sudo rm -rf /etc/cni/net.d/*kube-ovn*  # 删除 kube-ovn 相关的 CNI 配置
sudo rm -rf /etc/cni/net.d/10-kube-ovn.conflist  # 若存在单独的配置文件

# 清理 ovn/ovs 相关目录（避免权限或残留文件影响）
echo "清理 ovn/ovs 相关目录..."
sudo rm -rf /var/run/openvswitch
sudo rm -rf /var/run/ovn
sudo rm -rf /var/log/openvswitch
sudo rm -rf /var/log/ovn
sudo rm -rf /etc/origin/openvswitch
sudo rm -rf /etc/origin/ovn

# 执行 kubeadm reset 重置集群
echo "执行 kubeadm reset..."
sudo kubeadm reset --force

# 移除 kubelet 工作目录
echo "删除 kubelet 工作目录..."
sudo rm -rf /var/lib/kubelet

# 移除 etcd 数据目录（控制平面节点）
echo "删除 etcd 数据目录..."
sudo rm -rf /var/lib/etcd

# 移除 Kubernetes 配置残留
echo "删除 Kubernetes 配置文件..."
sudo rm -rf /etc/kubernetes
rm -rf /root/.kube/config

# 停止并删除所有 Kubernetes 相关容器（包括 kube-ovn 容器）
echo "清理 Kubernetes 相关容器..."
sudo docker rm -f $(sudo docker ps -q --filter name=k8s_) 2>/dev/null
sudo docker rm -f $(sudo docker ps -q --filter name=kube-ovn) 2>/dev/null  # 单独清理 kube-ovn 容器
sudo docker rm -f $(sudo docker ps -q --filter name=ovn) 2>/dev/null  # 清理 ovn 相关容器

# 删除 Kubernetes 相关镜像（包括 kube-ovn 镜像）
echo "清理 Kubernetes 相关镜像..."
sudo docker rmi $(sudo docker images -q --filter reference='k8s.gcr.io/*') 2>/dev/null
sudo docker rmi $(sudo docker images -q --filter reference='registry.aliyuncs.com/google_containers/*') 2>/dev/null
sudo docker rmi $(sudo docker images -q --filter reference='docker.m.daocloud.io/kubeovn/*') 2>/dev/null  # 清理 kube-ovn 镜像

echo "清理完成！"
