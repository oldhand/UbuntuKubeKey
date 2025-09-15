#!/bin/bash

# 检查是否以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：此脚本需要以root权限运行，请使用sudo执行"
    exit 1
fi

sudo chmod 755 $PWD

# 验证操作系统是否为Ubuntu 22.04
if ! grep -q "Ubuntu 22.04" /etc/os-release; then
    OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | sed 's/"//g')
    echo "此脚本专为 Ubuntu 22.04 设计，检测到不兼容的操作系统: $OS_NAME"
    exit 1
fi

# 禁用 Swap
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

# 关闭ufw防火墙（Ubuntu默认防火墙）
if systemctl is-active --quiet ufw; then
    systemctl stop ufw
    systemctl disable ufw
fi


if [ ! -f "images/kube-apiserver-v1.29.3.tar" ]; then
  cat $PWD/images/images.zip.001 $PWD/images/images.zip.002 $PWD/images/images.zip.003 $PWD/images/images.zip.004 $PWD/images/images.zip.005 > $PWD/images/images.zip
  unzip $PWD/images/images.zip -d $PWD/images/
  rm -fr $PWD/images/images.zip
fi

ansible-playbook -i hosts.ini install_k8s.yml
#ansible-playbook -i hosts.ini install_k8s.yml -k

#rm -fr $PWD/images/*.tar