#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")

docker build -t wsl-rockylinux9 .

docker create --name wsl-rockylinux9-container wsl-rockylinux9

docker export wsl-rockylinux9-container -o ${SCRIPT_DIR}/build/wsl-rockylinux9-container.tar

docker rm wsl-rockylinux9-container
