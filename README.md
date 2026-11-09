# IBus Rime · 雾凇、万象与春日绿

这是当前 IBus Rime 配置快照：默认雾凇小鹤双拼，另可在 F4 菜单切换雾凇全拼、万象小鹤双拼；默认英文、雾凇 Emoji 默认关闭、编码嵌入输入位置。雾凇每页 7 个候选，万象每页 6 个候选。

仓库包含两套词库和 Lua、用户词库文本快照，以及春日绿和云蓝深浅主题。**本仓库公开，`userdict/` 中导出的个人词汇可被任何人查看。**这些文件是备份时的快照，新学习的词不会自动上传。

## 安装

Ubuntu / Debian 的 GNOME 桌面会话中运行：

```bash
git clone https://github.com/luqiankun/ibus-rime.git
cd ibus-rime
./install.sh
```

脚本会检测缺失的软件包，使用 `sudo apt-get` 安装 IBus、ibus-rime、Rime 命令行工具、Lua 和 octagram 插件、GNOME 工具及当前主题所需字体。首次安装需要网络和可能的 sudo 密码。

万象模型约 399 MiB，脚本从官方 LTS 地址下载并用固定 SHA-256 校验，缓存于 `~/.cache/ibus-rime/`。LTS 文件如果被上游替换，校验会失败并停止安装；此时需更新仓库的校验值并验证兼容性，也可通过 `RIME_WANXIANG_MODEL=/path/to/wanxiang-lts-zh-hans.gram ./install.sh` 使用同一校验值的本地文件。安装前不会改动原 Rime 目录。

默认安装春日绿皮肤；也可选云蓝：

```bash
./install.sh spring # 黑底、白字、绿色高亮（默认）
./install.sh dark   # 云蓝暗色
./install.sh light  # 云蓝浅色
./install.sh auto   # 云蓝主题按 GNOME 夜灯切换
```

只安装皮肤可运行 `./install-theme.sh spring`。字体设置为当前的 `文鼎ＰＬ简报宋 Bold 18`，对应 Debian/Ubuntu 包 `fonts-arphic-gbsn00lp`。不同 GNOME 版本和应用的候选框可能有差异。

## 数据和恢复

安装会短暂停止 IBus，把原有 `~/.config/ibus/rime` 整体改名备份为同目录下 `rime.backup.*`，然后安装本仓库快照。目标机器原有的 `rime_ice`、`wanxiang`、`en`、`sequence`、`stats` 用户数据库会保留；前三者没有已有数据库时才导入仓库里的文本快照。导出格式不保证包含用户数据库的全部内部统计状态。其他旧文件保存在备份中，不会自动合并。

重新部署或迁移时，日常用户库仍需定期单独备份。IBus 和 Fcitx5 使用各自的用户目录，词频不会自动互通。安装完成后在 GNOME 输入源中选择 Rime；首次安装 Customize IBus 扩展后可能需要注销重新登录。主题 `auto` 按夜灯状态而非系统深浅外观切换。

## 内容

- `rime/`：雾凇和万象的输入方案、词库、OpenCC、Lua 与自定义配置。雾凇、小鹤和万象各自独立，万象语法模型通过安装脚本获取。
- `userdict/`：雾凇、万象和英文用户词库的文本备份。
- `themes/`：IBus 的春日绿与云蓝 CSS。
- `install.sh` / `install-theme.sh` / `install-deps.sh`：完整安装、仅皮肤、依赖检查。

雾凇拼音来自 [iDvel/rime-ice](https://github.com/iDvel/rime-ice)，许可证见 `rime/LICENSE`。万象方案与词库来自 [amzxyz/rime-wanxiang v18.1.10](https://github.com/amzxyz/rime-wanxiang/releases/tag/v18.1.10)，使用小鹤双拼、默认英文和 6 候选的自定义补丁；其上游许可证见 [WANXIANG-LICENSE](WANXIANG-LICENSE)。语法模型来自 [万象数据仓库 LTS](https://github.com/amzxyz/rime-wanxiang-data/releases/tag/LTS)，各数据组件适用上游声明。春日绿皮肤参考 [Candlelight](https://github.com/thep0y/fcitx5-themes-candlelight)，云蓝参考 [IBus Theme Hub](https://github.com/openSUSE/IBus-Theme-Hub)。

万象基础词库以压缩分片存放在 `data/`；安装脚本会自动合并、解压并校验，安装后恢复为完整的 `dicts/jichu.dict.yaml`。
