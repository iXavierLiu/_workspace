#!/bin/bash

# Edit the following variables
IMAGE_NAME=wsl-rockylinux9

# Construction variable
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONTAINER_NAME=${IMAGE_NAME}-container
OUTPUT_FILE=${SCRIPT_DIR}/build/${CONTAINER_NAME}.wsl
DOCKER_CLI=podman # or docker


$DOCKER_CLI build -t $IMAGE_NAME .

$DOCKER_CLI create --name $CONTAINER_NAME $IMAGE_NAME

$DOCKER_CLI export $CONTAINER_NAME -o $OUTPUT_FILE

$DOCKER_CLI rm $CONTAINER_NAME
