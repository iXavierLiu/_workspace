## 创建一个加密数据集
```shell
# 创建一个32字节随机数据密钥文件，并通过gpg加密
dd if=/dev/urandom bs=32 count=1 | gpg --armor --encrypt --sign --recipient xavier --local-user xavier --output keyfile.bin.asc

# 创建一个加密数据集，encryption指定加密，keyformat指定加密方式，keylocation指定加密文件位置，这里通过stdin每次从终端获取而不是固定位置，密码文件通过gpg解密后送进zfs
gpg --decrypt keyfile.bin.asc | sudo zfs create -o encryption=on -o keyformat=raw -o keylocation=file:///dev/stdin tank/encrypted

# 查看状态
zfs get encryption,keyformat,keylocation,keystatus tank/encrypted
```
`keystatus` 表示密钥状态：

`available`：密钥已加载，数据可访问。

`unavailable`：密钥未加载，数据被锁定。

**需要注意：** 密钥是会持久化装载到zfs中的，无论数据集是否卸载，**必须在数据集卸载后*手动显式卸载密钥***

## 数据集的卸载
```
# 卸载数据集
sudo zfs unmount tank/encrypted
# 卸载密钥
sudo zfs unload-key tank/encrypted
```

## 数据集的装载
```
# 装载数据集，这里的 `-l` 选项告诉 ZFS 先加载密钥，也可以用 `gpg --decrypt keyfile.bin.asc | sudo zfs load-key tank/encrypted` 进行密钥装载
gpg --decrypt keyfile.bin.asc | sudo zfs mount tank/encrypted -l
```
对于`tank/encrypted`下还有多个子数据集的话，可以这样一次进行快速挂载(zfs默认不会自动挂载加密数据集的子数据集，需要手动挨个挂载)
```
gpg --decrypt keyfile.bin.asc | sudo zfs load-key -r tank/encrypted && sudo zfs mount -a ; zfs list -o name,mounted
```
