#!/bin/bash

# 检查是否以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：此脚本需要以root权限运行，请使用sudo执行"
    exit 1
fi

# 验证操作系统是否为Ubuntu 22.04
if ! grep -q "Ubuntu 22.04" /etc/os-release; then
    OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | sed 's/"//g')
    echo "此脚本专为 Ubuntu 22.04 设计，检测到不兼容的操作系统: $OS_NAME"
    exit 1
fi

if [ ! -d "./packages" ]; then
    mkdir -p "./packages"
    chown -R _apt:root "./packages"
    chmod 755 "./packages"
fi

sudo apt remove -y systemd-timesyncd

echo "下载所有的依赖包..."
cd ./packages
sudo apt-get download -o Dir::Cache="./" -o Dir::Cache::archives="./" \
    net-tools openssh-client openssh-server openssh-sftp-server sshpass curl wget git git-man tar apt-rdepends dpkg-dev libdpkg-perl libfile-fcntllock-perl lto-disabled-list make \
    telnet bash-completion seccomp chrony

sudo apt-get download -o Dir::Cache="./" -o Dir::Cache::archives="./" \
    ansible python3 python3-apt python3-jinja2 python3-yaml python3-paramiko python3-pkg-resources python3-cryptography libcurl4 liberror-perl \
    ieee-data libapt-pkg-perl python-babel-localedata python3-babel python3-bcrypt python3-distutils python3-dnspython python3-lib2to3 python3-markupsafe python3-netaddr python3-packaging python3-pycryptodome python3-requests-toolbelt \
    python3-sniffio python3-trio ipython3 \
    openvswitch-common openvswitch-switch

sudo apt-get download -o Dir::Cache="./" -o Dir::Cache::archives="./" \
  binutils binutils-common binutils-x86-64-linux-gnu blt cpp-11 fonts-lyx g++ g++-11 gcc gcc-11 gcc-11-base gcc-12-base javascript-common libasan6 libatomic1 libbinutils libblas3 libboost-dev libboost1.74-dev libc-dev-bin libc-devtools libc6 libc6-dbg \
  libc6-dev libcc1-0 libcrypt-dev libctf-nobfd0 libctf0 libexpat1 libexpat1-dev libgcc-11-dev libgcc-s1 libgfortran5 libgomp1 libitm1 libjs-jquery libjs-jquery-ui libjs-sphinxdoc libjs-underscore liblapack3 liblbfgsb0 liblsan0 libnsl-dev libopenblas-dev \
  libopenblas-pthread-dev libopenblas0 libopenblas0-pthread libpython3-dev libpython3.10 libpython3.10-dev libpython3.10-minimal libpython3.10-stdlib libqhull-r8.0 libquadmath0 libstdc++-11-dev libstdc++6 libtirpc-dev libtk8.6 libtsan0 libubsan1 \
  libxsimd-dev linux-libc-dev manpages-dev python-matplotlib-data python3-appdirs python3-async-generator python3-attr python3-backcall python3-beniget python3-brotli python3-bs4 python3-cycler python3-decorator python3-dev python3-fonttools python3-fs \
  python3-gast python3-html5lib python3-ipython python3-jedi python3-kiwisolver python3-lxml python3-lz4 python3-matplotlib python3-matplotlib-inline python3-mpmath python3-numpy python3-outcome python3-parso python3-pickleshare python3-pil.imagetk \
  python3-ply python3-prompt-toolkit python3-pygments python3-pythran python3-scipy python3-sortedcontainers python3-soupsieve python3-sympy python3-tk python3-traitlets python3-ufolib2 python3-unicodedata2 python3-wcwidth python3-webencodings python3.10 \
  python3.10-dev python3.10-minimal rpcsvc-proto tk8.6-blt2.5 unicode-data zlib1g-dev

cd ..

echo "安装所有的依赖包..."
sudo dpkg -i ./packages/*.deb

# 修改SSH配置，允许root登录
echo "正在修改SSH配置..."

# 替换现有配置或添加新配置
if ! grep -q '^PermitRootLogin yes' /etc/ssh/sshd_config; then
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
fi
# 重启SSH服务使配置生效
echo "重启SSH服务..."
systemctl restart sshd

echo "操作完成！"
