```shell
docker build -t wsl-almalinux9 .
# 创建容器
docker create --name wsl-almalinux9-container wsl-almalinux9
# 导出 rootfs
docker export wsl-almalinux9-container -o wsl-almalinux9-container.tar
# 清理无用容器
docker rm wsl-almalinux9-container
```