#!/bin/bash

set -ue

# 根据构建修改
SRC_IMG="AlmaLinux-10.0_x64_20250529.0.wsl"
SRC_OS="almalinux"
SRC_VERSION="10.0"

# 变量
BUILD_IMG="wsl-build"
DST_NAME="wsl-${SRC_OS}-${SRC_VERSION}"

SCRIPT_DIR="$(dirname "$(realpath "$0")")"


podman import $SRC_IMG $BUILD_IMG

podman build -t $DST_NAME .

# 因为要导出rootfs而不是完整镜像，所以要先创建容器
podman create --name $DST_NAME $DST_NAME

podman export $DST_NAME -o "${SCRIPT_DIR}/build/${DST_NAME}_$(date +%Y%m%d_%H%M%S).wsl"

podman rmi -f $BUILD_IMG $DST_NAME
