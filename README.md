# 在Apple芯片(M1/2)的Mac上读写NTFS硬盘的开源解决方案

自从换了M2的Mac mini后，发现原先可以使用的读写NTFS硬盘的工具并不支持Apple的M系列芯片。虽然macOS系统支持挂载并读取NTFS格式的硬盘，但不支持写入。于是乎本着能用开源，则不付费的原则，找到了在M芯片Mac上读写NTFS硬盘的开源解决方案：[ntfs-3g-mac](https://github.com/osxfuse/osxfuse/wiki/NTFS-3G)

***<u>生命诚可贵，数据价更高！</u>***
***<u>生命诚可贵，数据价更高！</u>***
***<u>生命诚可贵，数据价更高！</u>***

> **友情提醒：**
> 1. 如果你没有使用过终端（Terminal）进行文件创建、读写、删除等操作
> 2. 如果你不知道sudo、mkdir等命令是干啥的
> 
> **那么本文不适合你！！！**

## 安装前提

确保你的电脑上已经安装了 [Command Line Tools for Xcode](https://developer.apple.com/download/more/) 和 [Homebrew](https://brew.sh/) ，可以用以下命令验证：

```sh
# 验证是否安装了Command Line Tools for Xcode
xcode-select -v
# 验证是否安装了Homebrew
brew -v
```

示例如下图：

![xcode-select-brew-v](http://sandslee.tpddns.cn:9000/public/xcode-select-brew-v.png)

## 安装macFUSE

进入[macFUSE主页](https://osxfuse.github.io/)，在右侧下载最新安装包：

![xcode-select-brew-v](http://sandslee.tpddns.cn:9000/public/macFUSE_download.png)

dmg文件下载后点击打开，点击安装，因为安装的是系统扩展，会弹出提示，要求关闭电脑，然后重新开机进入 Startup Security Utility；进入后，选择允许 signed 的 developer。如果这一步不能搞定，那么下面的就不用看了，本文不适合你。

重新开机后，打开设置，在最下方看到存在 macFUSE，则表示扩展安装成功了。

## 安装NTFS-3G

可以直接参考 [NTFS 3G Installation](https://github.com/osxfuse/osxfuse/wiki/NTFS-3G) 部分的说明。首先执行：

```sh
brew tap gromgit/homebrew-fuse
```

因为某些原因，使用https协议clone时会有如下错误：

```
==> Tapping gromgit/fuse
Cloning into '/opt/homebrew/Library/Taps/gromgit/homebrew-fuse'...
fatal: unable to access 'https://github.com/gromgit/homebrew-fuse/': LibreSSL SSL_read: error:02FFF03C:system library:func(4095):Operation timed out, errno 60
Error: Failure while executing; `git clone https://github.com/gromgit/homebrew-fuse /opt/homebrew/Library/Taps/gromgit/homebrew-fuse --origin=origin --template=` exited with 128.
```

可以考虑使用git协议：

```sh
git clone git@github.com:gromgit/homebrew-fuse.git /opt/homebrew/Library/Taps/gromgit/homebrew-fuse --origin=origin --template=
```

其本质就是要将GitHub上的 [gromgit/homebrew-fuse](https://github.com/gromgit/homebrew-fuse) 这个仓库克隆下来，并放到指定的brew仓库位置。

接下来，再执行：

```sh
brew install ntfs-3g-mac
```

到此，如果以上步骤全部顺利完成，那么恭喜你的Mac已经具备了读写NTFS硬盘的能力～🥳

## 读写NTFS硬盘

在开始读写NTFS硬盘之前，先介绍两个小知识点，技术大佬可以略过～🙏

系统想要往硬盘里写数据，那么需要两个东西，一个是挂载点，另一个是分区标志符。

#### 1. 挂载点

挂载点简单的说就是磁盘文件系统的入口目录。可以理解成当你把一块硬盘插入系统的时候，系统把它放到了哪里，相当于可以用挂载点找到你插入的硬盘。

#### 2. 分区标志符

通常一块硬盘都是要分区之后才可以使用的，而且可以分多个区，所以如果说挂载点是可以找到你的硬盘，那么分区标志符就是可以找到你硬盘具体的哪个分区。（**这个很重要！！！**）

---

首先连接硬盘，然后在macOS上可以使用diskutil命令查看硬盘挂载情况：

```sh
diskutil list
```

命令执行结果输出类似以下格式：

```
/dev/disk4 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *1.0 TB     disk4
   1:               Windows_NTFS Seagate Backup Plus ... 1.0 TB     disk4s1
```

> 说明：
> 开头的 /dev/disk4 这个就是挂载点（其实就是一个目录路径）
> IDENTIFIER 这一列下面对应的就是分区标志符，比如：disk4s1

因为macOS系统可以挂载NTFS硬盘为可读状态，所以需要先卸载（unmaount）再使用NTFS-3G挂载（mount）。

```sh
# 先卸载
sudo diskutil unmountDisk /dev/disk4

# 创建重新挂载目录
sudo mkdir /Volumes/YOUR_DISK_NAME

# 重新挂载
sudo mount_ntfs /dev/disk4s1 /Volumes/YOUR_DISK_NAME
```

> 提示：
> 1. sudo 命令执行需要输入电脑开机密码，输入时不会显示，输入完成回车即可
> 2. 挂载目录的路径格式必须是/Volumes/YOUR_DISK_NAME，但是硬盘名称可以自行指定，注意最好不要有中文、空格、特殊字符等
> 3. 注意重新挂载的时候使用的是NTFS对应的分区标志符进行挂载，而不再是整个挂载点

至此，NTFS硬盘读写模式挂载成功，打开挂载目录即可测试写入、删除文件。

---

## 自动挂载NTFS脚本

以上读写NTFS硬盘部分的命令每次都需要执行一遍，为了方便使用，本人简单的写了一段Shell脚本，可以配合Mac自带的 **自动操作app** ，实现插入硬盘后双击一下即可自动完成NTFS硬盘的挂载。

#### 1. 自动挂载脚本

***<u>划重点：如果你不知道脚本中大概在做什么事情，请不要使用该脚本！</u>***

Shell脚本如下：

```sh
#!/bin/bash

echo "TODO..."

```

> 注意：
> 1. 该脚本 **仅支持同时只有一个NTFS格式的硬盘** 使用
> 2. 该脚本只是根据个人测试编写，可能会存在解析硬盘信息时错误，欢迎issue或自行修改，issue时请附上 `diskutil list` 的完整输出

#### 2. 自动操作app

关于Mac自带的自动操作app如何使用就请各位老板自行谷歌了，我只能说，强大到爆！这里只简单介绍一下如何通过 [Mac“自动操作”将脚本封装为app](https://juejin.cn/post/7123098435254747149) 。

完成封装后，每次插上硬盘，双击，即可挂载完成。OK, Just enjoy it!🎉

