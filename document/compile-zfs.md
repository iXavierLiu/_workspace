# 编译zfs（创业未半而中道崩殂，遇到了严重的问题无法解决，因此本文档仅为存档）
由于zfs没有官方支持rehl10，以及对armv8不够【热情】，所以需要手动进行编译
需要提示的是，这里没有对宿主机进行环境隔离，如果需要可以在容器中进行
## 前期准备
参考 https://openzfs.github.io/openzfs-docs/Developer%20Resources/Building%20ZFS.html#build-options 
```shell
# 安装依赖
sudo dnf install --skip-broken epel-release gcc make autoconf automake libtool rpm-build libtirpc-devel libblkid-devel libuuid-devel libudev-devel openssl-devel zlib-devel libaio-devel libattr-devel elfutils-libelf-devel kernel-devel-$(uname -r) python3 python3-devel python3-setuptools python3-cffi libffi-devel git ncompress libcurl-devel
# 下载源代码，这里-e是设置代理
wget https://github.com/openzfs/zfs/releases/download/zfs-2.3.4/zfs-2.3.4.tar.gz -e https_proxy=http://localhost:7890
tar -zxvf zfs-2.3.4.tar.gz
cd zfs-2.3.4/
```

## 编译

```shell
# 构建configure
./autogen.sh
# 编译，-s指定静默(减少)输出，-j指定多线程，rpm指定编译为rpm包
make -s -j$(nproc) rpm
```

## 简单配置集安装
搭建一个本地源的zfs yum源仓库
```shell
sudo mkdir /opt/local.repo/zfs -p

sudo cp *.rpm /opt/local.repo/zfs/

# 生成yum元数据， sudo dnf install -y createrepo
sudo createrepo /opt/local.repo/zfs/

# 导入yum配置
cat > /etc/yum.repos.d/local-zfs.repo <<EOF

[local-zfs]
name=Local ZFS Repo
baseurl=file:///opt/local.repo/zfs
enabled=1
gpgcheck=0

EOF

# 

```
