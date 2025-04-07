```shell
# 确保已安装扩展源
sudo dnf install epel-release -y
# 安装 podman-docker
sudo dnf install podman-docker -y
```
配置加速，国内可用的加速镜像参考[链接](https://github.com/dongyubin/DockerHub)
```shell
mkdir -p ~/.config/containers/

# 仅docker.io
cat > ~/.config/containers/registries.conf << EOF
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "docker.io"
[[registry.mirror]]
location = "docker.m.daocloud.io"
insecure = false
EOF
```
验证

```shell
# sudo dnf install jq -y
podman info -f json | jq '.registries'
```

---
### 附录

多配置参考
```shell
cat > ~/.config/containers/registries.conf << EOF
# 默认搜索的registry
unqualified-search-registries = ["docker.io", "quay.io"]

# Docker Hub配置
[[registry]]
prefix = "docker.io"
location = "docker.io"
#[[registry.mirror]]
#location = "registry-1.docker.io"
[[registry.mirror]]
location = "docker.m.daocloud.io"
insecure = false

# Quay.io配置
[[registry]]
prefix = "quay.io"
location = "quay.io"
[[registry.mirror]]
location = "quay.mirrors.ustc.edu.cn"
insecure = false
EOF

```

