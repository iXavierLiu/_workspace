
常用工具
```shell
sudo dnf install -y bash-completion git
sudo dnf install -y gpg pinentry
```

## gpg

.bash_profile
```shell
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
```

.bashrc
```shell
# export
export GPG_TTY=$(tty)

# alias
alias gpg-bye="gpg-connect-agent updatestartuptty /bye"
```

## git

```shell
# git config --global --list

http.proxy=127.0.0.1:7890
user.name=Xavier Liu
user.email=i@xavierliu.io
user.signingkey=B72EA600!
commit.gpgsign=true
core.autocrlf=input
core.ignorecase=false
```
