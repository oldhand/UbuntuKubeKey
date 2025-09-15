#!/bin/bash
# 脚本：export_k8s_images.sh
set -euo pipefail  # 严格模式，遇到错误立即退出

REPO_PREFIX="registry.cn-hangzhou.aliyuncs.com/google_containers"  # 镜像源
K8S_VERSION="v1.29.3"

# 镜像列表（与集群版本匹配）
images=(
  "kube-apiserver:${K8S_VERSION}"
  "kube-controller-manager:${K8S_VERSION}"
  "kube-scheduler:${K8S_VERSION}"
  "kube-proxy:${K8S_VERSION}"
  "pause:3.9"
  "etcd:3.5.16-0"
  "coredns:v1.11.1"
)

# 检查基础网络连接
check_network() {
  local test_sites=("baidu.com" "aliyun.com" "163.com")
  for site in "${test_sites[@]}"; do
    if ping -c 1 -W 3 "$site" >/dev/null 2>&1; then
      return 0  # 网络可用
    fi
  done
  echo "错误：网络连接不可用，请检查网络设置"
  exit 1
}

# 检查镜像是否已存在
image_exists() {
  local image="$1"
  if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
    return 0  # 镜像存在
  else
    return 1  # 镜像不存在
  fi
}

# 主逻辑
check_network  # 先检查网络

# 循环处理镜像
for img in "${images[@]}"; do
  full_image="${REPO_PREFIX}/${img}"
  echo -e "\n处理镜像: $full_image"

  # 检查镜像是否已存在
  if image_exists "$full_image"; then
    echo "镜像已存在，无需拉取: $full_image"
  else
    # 拉取镜像
    if ! docker pull "$full_image"; then
      echo "警告：拉取 $img 失败，跳过该镜像"
      continue
    fi
  fi

  # 导出镜像
  tar_file="${img//:/-}.tar"  # 替换为 "镜像名-版本.tar"
  if docker save "$full_image" -o "$tar_file"; then
    echo "成功导出: $tar_file"
  else
    echo "警告：导出 $img 失败"
  fi
done

echo -e "\n所有镜像处理完成"
