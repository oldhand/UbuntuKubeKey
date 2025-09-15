#!/bin/bash


# 检查是否以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：此脚本需要以root权限运行，请使用sudo执行"
    exit 1
fi

echo "安装所有的依赖包..."
sudo dpkg -i ./packages/*.deb

sudo ansible-galaxy collection install $(pwd)//kubernetes-core-6.1.0.tar.gz --force

sudo pip install --no-index --find-links=$(pwd)/pip kubernetes PyYAML