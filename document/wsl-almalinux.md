
# 本文档存在问题
## *已知almalinux对wsl的systemd/dbus有兼容问题，仅供参考*
需要提示的是，经过测试，同时只能有一个wsl容器获取dbus权限

## wsl中安装almalinux发行版

进入[官网](https://almalinux.org/get-almalinux/)在`AlmaLinux OS UBI-alternatives`标签中看到以下可用类型

- almalinux/9-minimal
- almalinux/9-base
- almalinux/9-init
- almalinux/9-micro

我们选择`base`类型，在任意具有docker的环境下

```shell
# 拉取镜像
docker pull almalinux/9-base
# 创建容器
docker create --name almalinux_9_base_container almalinux/9-base
# 导出 rootfs
docker export almalinux_9_base_container -o almalinux_9_base_container.tar
# 清理无用容器
docker rm almalinux_9_base_container
```

然后在windows的shell中

```shell
wsl --import almalinux-9 /e/WSL/ almalinux_9_base_container.tar
```

导入完成后进行基本的初始化

```shell
# 进入发行版
wsl -d almalinux-9

# 安装必要软件包
dnf update -y
dnf install sudo vim -y

# 添加用户并设置密码
adduser xavier
passwd xavier

# 添加管理员权限
usermod -aG wheel xavier
groups xavier

# 启用systemd服务，设置默认用户
cat > /etc/wsl.conf << EOF
[boot]
systemd = true

[user]
default = xavier
EOF

# 推出发行版
exit
```

备份
```shell
wsl --export almalinux-9 almalinux-9-$(date +'%Y%m%d_%H%M%S')_backup.tar
```

验证

```shell
# 中止运行
wsl -t almalinux-9

# 运行发行版
wsl -d almalinux-9

# 检查用户是否为设置的 xavier
whoami

# 检查systemd是否正常
systemctl status
```
