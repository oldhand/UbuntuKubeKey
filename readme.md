# UbuntuKubeKey：Kubernetes 自动化部署工具

## 仓库简介
基于 Ansible 的 Kubernetes 集群自动化部署工具，专为 **Ubuntu 22.04 LTS** 系统设计，可快速搭建 Kubernetes 1.29 版本集群。通过预设角色和自动化任务，简化部署流程，确保环境一致性与稳定性。


## 核心优势
1. **全自动化部署**  
   从环境初始化到集群集群启动全流程自动化，用户仅需配置 `hosts.ini` 并运行部署命令，减少手动操作与人为错误。

2. **深度适配 Ubuntu**  
   针对 Ubuntu 系统特性优化（系统 bug 修复、包管理适配等），相比通用工具（如 kubeadm）更稳定可靠。

3. **版本可控与兼容性**  
   固化组件版本（Kubernetes 1.29、Docker 25.0.0 等），通过变量文件统一管理，避免版本冲突。

4. **离线部署支持**  
   内置所有依赖安装包与仓库配置，可在无外网环境部署，适合内网或隔离场景。

5. **可扩展与可配置**  
   支持自定义集群参数（Pod/Service CIDR、VIP 地址等），满足不同网络环境需求。

6. **完善的校验机制**  
   部署过程包含系统版本校验、组件安装检查、配置文件验证，问题可通过日志快速定位。


## 核心结构
### 配置文件
- `ansible.cfg`：Ansible 运行参数配置
- `hosts.ini`：集群节点清单（定义主节点、工作节点、负载均衡节点角色）
- `install_k8s.yml`：主部署剧本（按顺序调用各角色任务）

### 角色（roles）目录
- `init`：系统环境初始化（操作系统校验、依赖安装、防火墙/swap 禁用、NTP 同步等）
- `docker`：容器运行时部署（Docker 安装、cri-dockerd 配置、镜像仓库加速等）
- `cluster`：Kubernetes 集群部署（kubeadm/kubelet 安装、集群初始化、节点加入、网络插件部署等）

### 其他文件
- 安装包：`docker-25.0.0.tgz`、`helm-v3.15.0-linux-amd64.tar.gz`、`cri-dockerd-0.3.4.amd64.tgz` 等
- 部署脚本：`install.sh`（封装部署命令，自动预处理环境）
- 辅助脚本：`dhcp_to_static.sh`（DHCP 转静态 IP）、`kube_clear.sh`（集群清理）、`export_k8s_images.sh`（镜像导出）


## 部署步骤
### 前提条件
1. 目标节点需为 **Ubuntu 22.04 LTS** 系统
2. Ansible 控制节点需能通过 SSH 无密码访问所有目标节点
3. 确保 `hosts.ini` 中 IP 地址与角色参数（`is_master`/`is_init`/`lb_master` 等）正确

### 1. 准备仓库
```bash
git clone <仓库地址>
cd <仓库目录>
```

### 2. 配置主机清单（`hosts.ini`）
定义集群节点角色，示例：
```ini
[k8s]
192.168.0.106 is_master=1 is_worker=1 is_init=1  # 初始化节点（主节点+工作节点）
192.168.0.116 is_master=1 is_worker=1            # 其他主节点

[lb]
192.168.0.106 lb_master=1  # 负载均衡主节点
192.168.0.116 lb_master=0  # 负载均衡备用节点
```
- `[k8s]`：Kubernetes 节点，`is_init=1` 为第一个主节点（初始化节点）
- `[lb]`：负载均衡节点，通过 keepalived 实现 VIP 高可用

### 3. 安装前准备
#### 步骤 1：安装基础依赖
```bash
chmod +x install_package.sh
./install_package.sh  # 安装 net-tools、python3、git 等依赖
```

#### 步骤 2：DHCP 转静态 IP（如需）
```bash
chmod +x dhcp_to_static.sh
sudo ./dhcp_to_static.sh  # 自动检测网络接口并配置静态 IP
```

#### 步骤 3：更新 IP 配置文件
```bash
chmod +x update_ip.sh
./update_ip.sh  # 自动修改配置文件中的本地 IP
```

### 4. 执行部署
#### 方式 1：直接运行 Ansible 剧本
```bash
ansible-playbook -i hosts.ini install_k8s.yml -k  # -k 用于输入 SSH 密码
```

#### 方式 2：通过部署脚本运行（推荐）
```bash
chmod +x install.sh
./install.sh  # 自动禁用 Swap、关闭防火墙并执行部署
```


## 部署流程说明
1. **系统环境初始化（`[k8s]` 节点）**
   - 校验操作系统版本（仅支持 Ubuntu 22.04）
   - 配置本地源、安装基础依赖
   - 禁用防火墙、Swap，配置 NTP 时间同步
   - 设置主机名、DNS 与 IPVS 规则

2. **容器运行时部署（`[k8s]` 节点）**
   - 从本地包安装 Docker 25.0.0 与 cri-dockerd 0.3.4
   - 配置 cgroup 驱动（与 kubelet 一致）、镜像仓库加速

3. **Kubernetes 集群部署**
   - 安装 kubeadm、kubelet、kubectl
   - 初始化集群（`is_init=1` 节点）
   - 加入其他主节点与工作节点
   - 安装 Helm 与 Kube-OVN 网络插件


## 验证部署结果
在任意主节点执行以下命令，确认集群状态：
```bash
# 查看节点状态（所有节点应处于 Ready 状态）
kubectl get nodes

# 查看系统组件状态（所有 Pod 应处于 Running 状态）
kubectl get pods -A
```


## 注意事项
1. **参数调整**
   - 集群参数（Pod/Service CIDR、K8s 版本）：修改 `roles/cluster/vars/main.yml`
   - 负载均衡 VIP（默认 `192.168.0.106`）：修改 `roles/lb/vars/main.yml`

2. **依赖检查**  
   确保 `docker-25.0.0.tgz`、`cri-dockerd-0.3.4.amd64.tgz` 等安装包已在仓库根目录（`docker` 角色会自动校验）。

3. **问题排查**
   - 部署错误可查看 Ansible 输出日志或目标节点临时日志（`/tmp/kubeadm-init.log`）
   - 节点加入失败：检查网络连通性、VIP 配置及 `hosts.ini` 参数


## 脚本文件说明
1. **`install.sh`**
   - 功能：部署流程封装，自动禁用 Swap、关闭防火墙并调用 Ansible 剧本
   - 使用：`chmod +x install.sh && ./install.sh`

2. **`dhcp_to_static.sh`**
   - 功能：将 DHCP 网络配置转为静态 IP（适用于 openEuler 22.03 LTS）
   - 使用：`sudo ./dhcp_to_static.sh`

3. **`kube_clear.sh`**
   - 功能：清理集群残留数据（重置 kubeadm、删除工作目录与配置文件）
   - 使用：`./kube_clear.sh`

4. **`export_k8s_images.sh`**
   - 功能：导出 K8s 组件镜像（用于离线部署）
   - 使用：修改脚本内镜像列表后执行，生成 `.tar` 格式镜像文件


## 卸载与重置
如需重置集群环境，在所有节点执行：
```bash
./kube_clear.sh  # 清理 K8s 残留数据
```
> 注意：此操作会删除集群所有数据，需谨慎执行。