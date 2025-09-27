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
# 查看
zpool list -v
```
