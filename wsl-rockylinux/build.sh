#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")
IMAGE_NAME=wsl-rockylinux9
CONTAINER_NAME=${IMAGE_NAME}-container

docker build -t ${IMAGE_NAME} .

docker create --name ${CONTAINER_NAME} ${IMAGE_NAME}

docker export ${CONTAINER_NAME} -o ${SCRIPT_DIR}/build/${CONTAINER_NAME}.tar

docker rm ${CONTAINER_NAME}
