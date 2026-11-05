#!/usr/bin/env bash
set -euo pipefail
# 仅管理软件包，保持用户目录操作在普通用户下执行。
mode=${1:-all}
case "$mode" in all|theme) ;; *) printf '用法：%s [all|theme]\n' "$0" >&2; exit 2 ;; esac
if [ "$(id -u)" -eq 0 ]; then
  printf '请作为桌面用户运行脚本；安装系统依赖时会自动调用 sudo。\n' >&2
  exit 1
fi
if ! command -v dpkg-query >/dev/null || ! command -v apt-get >/dev/null; then
  printf '自动安装目前仅支持 Ubuntu / Debian 系（apt）。请在此系统安装等效依赖后使用对应桌面环境。\n' >&2
  exit 1
fi
# 雾凇使用 Lua 扩展；librime-bin 提供 rime_deployer 和 rime_dict_manager。
packages=(gnome-shell python3 curl)
if [ "$mode" = all ]; then
  packages+=(ibus ibus-rime librime-bin librime-data librime-plugin-lua)
fi
missing=()
for package in "${packages[@]}"; do
  status=$(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null || true)
  [ "$status" = installed ] || missing+=("$package")
done
if [ "${#missing[@]}" -eq 0 ]; then
  printf '系统依赖已安装。\n'
  exit 0
fi
command -v sudo >/dev/null || { printf '安装缺少的系统依赖需要 sudo，请先安装并配置 sudo。\n' >&2; exit 1; }
printf '将通过 apt 安装缺少的软件包：%s\n' "${missing[*]}"
sudo apt-get update
sudo apt-get install -y -- "${missing[@]}"
for package in "${missing[@]}"; do
  status=$(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null || true)
  [ "$status" = installed ] || { printf '软件包安装未完成：%s\n' "$package" >&2; exit 1; }
done
printf '系统依赖安装完成。\n'
