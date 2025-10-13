FROM localhost/wsl-build

# set mirror
RUN sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    	-e 's|^#\s*baseurl=https://repo.almalinux.org/almalinux|baseurl=https://mirrors.aliyun.com/almalinux|g' \
    	-i.bkup \
    	/etc/yum.repos.d/almalinux-*.repo && \
	dnf install -y epel-release && \
	sed -e 's|^metalink=|#metalink=|g' \
    	-e 's|^#baseurl=|baseurl=|g' \
    	-e 's|https\?://download\.fedoraproject\.org/pub/epel|https://mirrors.aliyun.com/epel|g' \
    	-e 's|https\?://download\.example/pub/epel|https://mirrors.aliyun.com/epel|g' \
    	-i.bkup \
		/etc/yum.repos.d/epel{,-testing}.repo


# common package
RUN dnf config-manager --set-enabled crb && \
	dnf update -y && \
	dnf group install -y "Development Tools" && \
	dnf install -y \
		vim-minimal \
		htop \
		man \
		gpg pinentry \
		ffmpeg-free \
		python3 python3-pip \
		podman && \
	dnf clean all && \
	pip install podman-compose && \
	pip cache purge
		
# set nopasswd for sudo
RUN sed -e '/^%wheel\s\+ALL=(ALL)\s\+ALL\s*$/ s/^/# /' \
		-e '/^#\s*%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s*ALL\s*$/ s/^#\s*//' \
		-i \
		/etc/sudoers

# init script
RUN cat >> /usr/lib/wsl/oobe <<'EOF_SCRIPT'

exec su - $username <<'EOF_SU'
# git config
git config --global http.proxy 127.0.0.1:7890
git config --global user.name Xavier Liu
git config --global user.email i@xavierliu.io
git config --global user.signingkey B72EA600!
git config --global commit.gpgsign true
git config --global log.showSignature true
git config --global core.autocrlf input
git config --global core.ignorecase false
git config --global init.defaultBranch master

# git config, use ssh with 443 port
mkdir -p $HOME/.ssh/
cat >> $HOME/.ssh/config <<'EOF'
Host github.com
    Hostname ssh.github.com
    Port 443
    User git

Host *
    ServerAliveInterval 60
    ServerAliveCountMax 1440
EOF

# bash_profile
cat >> $HOME/.bash_profile <<'EOF'
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
EOF

# bashrc
mkdir -p $HOME/.bashrc.d/
cat >> $HOME/.bashrc.d/gpg.bashrc <<'EOF'
export GPG_TTY=$(tty)
alias gpg-bye="gpg-connect-agent updatestartuptty /bye"
EOF

# podman
mkdir -p $HOME/.config/containers/registries.conf.d/
cat >> $HOME/.config/containers/registries.conf.d/mirror.conf <<'EOF'
# unqualified-search-registries = ["docker.io", "ghcr.io"]

# [[registry]]
# prefix = "docker.io"
# location = "10.67.0.110:56700"
# insecure = true

# [[registry]]
# prefix = "ghcr.io"
# location = "10.67.0.110:56701"
# insecure = true
EOF

# gpg
gpg --keyserver keyserver.ubuntu.com --recv-keys 8D22F3FF8E0DD49C757E891AB21CCCEA038C372D
mkdir -p $HOME/.gnupg/ && echo FCFC3AC00C20A3F8D7B897A76783C3B6562377FB >> $HOME/.gnupg/sshcontrol

EOF_SU
EOF_SCRIPT
