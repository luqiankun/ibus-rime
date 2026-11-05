# 云蓝 · IBus Rime 配置、词库和主题

这是当前 IBus 雾凇拼音环境的快照：全拼与小鹤双拼混输、每页 7 个候选、默认英文、行内显示编码、用户词频，以及云蓝浅色和暗色候选框主题。

**隐私：`userdict/rime_ice.txt` 含有输入历史形成的个人词汇和词频，本仓库为公开仓库，请留意这些内容可被任何人查看。** 备份是创建仓库时的快照，不会自动更新；之后学到的新词需要重新导出。

## 内容

- `rime/`：雾凇拼音源配置、中文和英文词库、Lua 脚本，以及本机的 `*.custom.yaml` 配置。上游快照版本：`99662ba01e3affa6a0f009174ca530b887bac3b6`。
- `userdict/rime_ice.txt`：从用户词库导出的文本备份，用于在新设备导入。导入行为由目标设备的 librime 实现，不能保证保存数据库内部所有统计或历史状态。
- `themes/`：不透明云蓝浅色和暗色皮肤。间距与圆角随字体大小缩放。
- `install.sh`：安装 Rime 配置、词库与皮肤；`install-theme.sh` 可只安装皮肤。

## 安装

在 Ubuntu / Debian 的 GNOME 桌面会话中克隆此仓库并运行：

```bash
git clone git@github.com:luqiankun/ibus-rime.git
cd ibus-rime
./install.sh
```

默认使用暗色皮肤，也可选择：

```bash
./install.sh dark   # 固定暗色
./install.sh light  # 固定浅色
./install.sh auto   # 由 Customize IBus 按夜灯状态切换
```

脚本自动检查并通过 apt 安装缺失的 IBus、ibus-rime、librime 工具、Lua 插件、GNOME Shell、Python 3 和 curl；安装系统软件包时会调用 sudo，可能需要输入密码和连接网络。自动安装目前仅支持 Ubuntu / Debian 系。

安装会短暂重启 IBus，将原有 `~/.config/ibus/rime` 完整改名备份在同目录下的 `rime.backup.*`，再安装本仓库的快照。如果目标机器已有 `rime_ice.userdb`，脚本保留它并跳过导入，以免覆盖已有学习记录；没有时才导入仓库中的个人词频快照。其他已有的方案和配置保存在备份目录，不会自动合并到新配置。遇到问题时可退出 IBus，再从备份目录恢复。

主题文件复制到 `${XDG_DATA_HOME:-~/.local/share}/ibus-themes/`。脚本会覆盖该目录下同名的两个主题文件；不会改写候选字体的扩展设置，也不携带字体文件。选择 `auto` 时跟随的是扩展的夜灯机制，并非系统深浅色外观。

如果缺少 Customize IBus，脚本会自动从 [GNOME 扩展网站](https://extensions.gnome.org/extension/4112/customize-ibus/)下载适配当前 GNOME 版本的扩展。新安装扩展如未能立刻启用，请注销并重新登录，再运行脚本。不同 GNOME 版本与应用可能有不同的显示效果。

## 许可与致谢

仓库中雾凇拼音及主题以 GPL-3.0-or-later 发布，详见各目录中的许可文件。皮肤参考 [IBus Theme Hub](https://github.com/openSUSE/IBus-Theme-Hub)，适用于 [Customize IBus](https://github.com/openSUSE/Customize-IBus)。
