```shell
# 确保已安装扩展源
sudo dnf install epel-release -y
# 安装ffmpeg
sudo dnf install ffmpeg-free -y
```
可能会看到以下错误
```text
Error:
 Problem: package ffmpeg-free-5.1.4-3.el9.x86_64 from epel requires libavfilter.so.8()(64bit), but none of the providers can be installed
  - package ffmpeg-free-5.1.4-3.el9.x86_64 from epel requires libavfilter.so.8(LIBAVFILTER_8)(64bit), but none of the providers can be installed
  - package ffmpeg-free-5.1.4-3.el9.x86_64 from epel requires libavfilter-free(x86-64) = 5.1.4-3.el9, but none of the providers can be installed
  - package libavfilter-free-5.1.4-3.el9.x86_64 from epel requires librubberband.so.2()(64bit), but none of the providers can be installed
  - conflicting requests
  - nothing provides ladspa needed by rubberband-3.1.3-2.el9.x86_64 from epel
(try to add '--skip-broken' to skip uninstallable packages or '--nobest' to use not only best candidate packages)
```
错误中很明显看到了缺少`rubberband`，但是当你尝试`sudo dnf install rubberband -y`安装时，你会看到以下错误
```text
Error:
 Problem: conflicting requests
  - nothing provides ladspa needed by rubberband-3.1.3-2.el9.x86_64 from epel
(try to add '--skip-broken' to skip uninstallable packages or '--nobest' to use not only best candidate packages)
```
如果根据错误提示来排查问题，那很可能无法解决问题并越来越困惑，其实最简单的方法是通过`sudo dnf config-manager --set-enabled crb`启用crb仓库

启用crb仓库并安装ffmpeg
```
sudo dnf config-manager --set-enabled crb
sudo dnf install ffmpeg-free -y
```

CRB 仓库是什么？
CRB(CodeReady Linux Builder)是一个附加仓库，包含了开发工具、编译器、库、以及其他开发相关的软件包。这些软件包通常不是由默认的 RHEL 或 CentOS 基本仓库提供，而是为开发人员提供更多的选择。启用 CRB 仓库可以让你安装和使用这些额外的软件包。