FROM almalinux/9-base

RUN sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^# baseurl=https://repo.almalinux.org|baseurl=https://mirrors.aliyun.com|g' \
    -i.bak \
    /etc/yum.repos.d/almalinux-*.repo

# 安装 systemd 及必要组件
RUN dnf -y install \
	sudo \
	vim \
	systemd \
	procps-ng \
	epel-release \
	bash-completion \
	&& \
    dnf clean all

RUN sed -e 's|^metalink=|#metalink=|g' \
    -e 's|^#baseurl=https://download.example/pub|baseurl=https://mirrors.aliyun.com|g' \
    -i.bak \
    /etc/yum.repos.d/epel{,-testing}.repo


COPY --chmod=644 wsl.conf /etc/wsl.conf

COPY --chmod=644 terminal-profile.json /usr/share/wsl/terminal-profile.json

COPY --chmod=644 wsl-distribution.conf /etc/wsl-distribution.conf

COPY --chmod=644 icon.png /usr/share/wsl/icon.png

COPY --chmod=755 oobe /usr/lib/wsl/oobe

# 强制 systemd 作为 PID 1
#CMD ["/usr/lib/systemd/systemd", "--system"]
