default way
```shell
# import
wsl --import rockylinux9 /e/WSL/rockylinux9 wsl-rockylinux9-container.tar

# run
wsl -d rockylinux9
```

OR
recomand way

```shell
# change extension
cp wsl-rockylinux9-container.tar wsl-rockylinux9-container.wsl
# install
wsl --install --from-file wsl-rockylinux9-container.wsl --location /e/WSL/rockylinux9

# run
wsl -d rockylinux9
```

wsl install will execute extr init.
