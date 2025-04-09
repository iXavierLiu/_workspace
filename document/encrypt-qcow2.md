```shell
# 创建镜像文件
qemu-img create -f qcow2 /mnt/w/workspace-pv.qcow2 20G

# 加载 NBD 内核模块
sudo modprobe nbd

# 将镜像接入为块设备
sudo qemu-nbd --connect /dev/nbd0 /mnt/w/workspace-pv.qcow2

# 格式化磁盘(裸磁盘、无分区)
sudo mkfs.ext4 /dev/nbd0

# 挂载到workspace-pv中，并修改权限
mkdir -p workspace-pv
sudo mount /dev/nbd0 workspace-pv
sudo chown xavier:xavier workspace-pv

# 生成4K字节的密钥，并通过GPG加密
dd if=/dev/urandom bs=4K count=1 | gpg --encrypt --recipient xavier --output workspace-pv/.encfs-keyfile.gpg

# 通过解密后的密钥文件对`encrypt-data`中的操作映射到`.encrypt-data`中并进行加密存储
encfs --extpass="gpg --quiet --decrypt ~/workspace-pv/.encfs-keyfile.gpg" --standard ~/workspace-pv/.encrypt-data ~/workspace-pv/encrypt-data

```


```shell
# 卸载加密文件系统
fusermount -u workspace-pv/encrypt-data

# 卸载镜像
sudo umount workspace-pv

# 断开 NBD 连接
sudo qemu-nbd --disconnect /dev/nbd0
```
