## 创建一个5盘位的【降级6盘raidz2】
```shell
# 创建一个15T(不要小于实际raid中的最小盘)逻辑大小的占位文件(并不实际占用)
truncate -s 15T /tmp/fake.img
# 挂载
sudo losetup /dev/loop10 /tmp/fake.img
# 查看磁盘 
ls -la /dev/disk/by-id/
# 创建一个5盘位的【降级6盘raidz2】
sudo zpool create -o ashift=12 tank raidz2 ata-{1} ata-{2} ata-{3} ata-{4} ata-{5} /dev/loop10
# 使占位盘失效
sudo zpool offline tank /dev/loop10
# 卸载占位盘
sudo losetup -d /dev/loop10
# 清理
rm /tmp/fake.img
```

## 问题
sudo 找不到 zfs命令
```shell
$ sudo zpool --version
sudo: zpool: command not found 
$ zpool --version
zfs-2.3.4-1
zfs-kmod-2.3.4-1
$ which zpool
/usr/local/sbin/zpool
```
原因是sudo 的一个安全配置项，定义了执行 sudo 命令时的环境变量 PATH，里面不包含zfs的安装路径`/usr/local/sbin/zpool`
```shell
echo "Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin" | sudo tee /etc/sudoer
s.d/zfs_path
```
