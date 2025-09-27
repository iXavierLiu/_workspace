# 编译zfs（创业未半而中道崩殂，遇到了严重的问题无法解决，因此本文档仅为存档）
由于zfs没有官方支持rehl10，以及对armv8不够【热情】，所以需要手动进行编译
需要提示的是，这里没有对宿主机进行环境隔离，如果需要可以在容器中进行
## 前期准备
参考 https://openzfs.github.io/openzfs-docs/Developer%20Resources/Building%20ZFS.html#build-options 
```shell
# 安装依赖, 或者可以尝试 sudo dnf groupinstall "Development Tools"
sudo dnf install --skip-broken epel-release gcc make autoconf automake libtool rpm-build libtirpc-devel libblkid-devel libuuid-devel libudev-devel openssl-devel zlib-devel libaio-devel libattr-devel elfutils-libelf-devel kernel-devel-$(uname -r) python3 python3-devel python3-setuptools python3-cffi libffi-devel git ncompress libcurl-devel

# 安装dkms
git clone https://github.com/dell/dkms.git
cd dkms/
sudo make install-redhat

# 安装zfs
git clone https://github.com/openzfs/zfs.git --config "http.proxy=localhost:7890"
cd zfs/
git checkout zfs-2.3.4
sh autogen.sh
./configure; make -s -j$(nproc)
sudo make install; sudo ldconfig; sudo depmod
sudo modprobe zfs
```

