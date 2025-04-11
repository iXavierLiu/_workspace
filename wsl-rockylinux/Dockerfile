FROM rockylinux:9

# Change the yum source to aliyun
RUN sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' \
    -i.bak \
    /etc/yum.repos.d/rocky{,-*}.repo

# Install `systemd` and necessary components
RUN dnf -y install \
	sudo \
	vim \
	systemd \
	procps-ng \
	epel-release \
	bash-completion \
	&& \
    dnf clean all

# Change the yum source to aliyun
RUN sed -e 's|^metalink=|#metalink=|g' \
    -e 's|^#baseurl=https://download.example/pub|baseurl=https://mirrors.aliyun.com|g' \
    -i.bak \
    /etc/yum.repos.d/epel{,-testing}.repo

# For wsl distribution
COPY --chmod=644 wsl.conf /etc/wsl.conf
COPY --chmod=644 terminal-profile.json /usr/share/wsl/terminal-profile.json
COPY --chmod=644 wsl-distribution.conf /etc/wsl-distribution.conf
COPY --chmod=644 icon.png /usr/share/wsl/icon.png
COPY --chmod=755 oobe /usr/lib/wsl/oobe
