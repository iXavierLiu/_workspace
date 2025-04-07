FROM quay.io/podman/stable:latest AS build

USER podman
RUN podman pull docker.io/almalinux/9-base && \
    podman save docker.io/almalinux/9-base -o /home/podman/almalinux_9-base.tar

# 因为挂载到内存导致目录结构变化，所以build阶段不可省略，只能等容器运行后在导入
FROM quay.io/podman/stable:latest

COPY --from=build /home/podman/almalinux_9-base.tar /almalinux_9-base.tar

COPY --chmod=755 sandbox /bin/sandbox

#CMD ["/bin/sandbox"]
