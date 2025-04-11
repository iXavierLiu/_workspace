FROM wsl-rockylinux9

RUN dnf config-manager --set-enabled crb \
	&& \
	dnf update -y \
	&& \
	dnf install -y \
		htop \
		man \
		git \
		gpg pinentry \
		ffmpeg-free \
		python3 python3-pip \
		gcc g++ cmake \
		autoconf automake libtool \
		kmod e2fsprogs \
	&& \
	dnf clean all
		
# init script
RUN cat >> /usr/lib/wsl/oobe <<'EOF_SCRIPT'

exec su - $username <<'EOF_SU'
# git config
git config --global commit.gpgsign true
git config --global log.showSignature true
git config --global core.autocrlf input
git config --global core.ignorecase false

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

EOF_SU
EOF_SCRIPT
