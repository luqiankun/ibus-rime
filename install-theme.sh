#!/usr/bin/env bash
set -euo pipefail

# 安装云蓝皮肤；仅修改 Customize IBus 的主题设置。
usage() {
  cat <<'HELP'
用法：./install-theme.sh [dark|light|auto]
  dark   固定暗色（默认）
  light  固定浅色
  auto   按 Customize IBus 的夜灯状态切换深浅主题
HELP
}
mode=${1:-dark}
case "$mode" in
  dark|light|auto) ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then usage >&2; exit 2; fi
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
"$script_dir/install-deps.sh" theme
for cmd in gsettings gnome-extensions gnome-shell; do
  command -v "$cmd" >/dev/null || { printf '缺少 %s，请先安装 GNOME Shell 和 GNOME 扩展工具。\n' "$cmd" >&2; exit 1; }
done
uuid='customize-ibus@hollowman.ml'
schema=org.gnome.shell.extensions.customize-ibus
ext_dir="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/$uuid"
theme_dir="${XDG_DATA_HOME:-$HOME/.local/share}/ibus-themes"
for theme in macos-sky.css macos-sky-dark.css; do
  [ -f "$script_dir/themes/$theme" ] || { printf '找不到主题文件：%s\n' "$theme" >&2; exit 1; }
done
if ! gnome-extensions info "$uuid" >/dev/null 2>&1; then
  for cmd in curl python3; do
    command -v "$cmd" >/dev/null || { printf '安装扩展需要 %s。\n' "$cmd" >&2; exit 1; }
  done
  shell_version=$(gnome-shell --version | awk '{print $3}' | cut -d. -f1)
  info=$(curl -fsSL --max-time 30 "https://extensions.gnome.org/extension-info/?uuid=customize-ibus%40hollowman.ml&shell_version=$shell_version")
  download_path=$(printf '%s' "$info" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("download_url", ""))')
  case "$download_path" in /download-extension/*) ;; *) printf 'GNOME 扩展网站未提供适用于当前版本的扩展。\n' >&2; exit 1 ;; esac
  temp_dir=$(mktemp -d)
  trap 'rm -rf -- "$temp_dir"' EXIT
  curl -fsSL --max-time 60 "https://extensions.gnome.org$download_path" -o "$temp_dir/customize-ibus.zip"
  gnome-extensions install "$temp_dir/customize-ibus.zip"
  printf '已安装 Customize IBus 扩展。\n'
fi
# 系统安装的扩展也可能不在用户目录。
if [ ! -f "$ext_dir/schemas/gschemas.compiled" ]; then
  ext_dir=$(gnome-extensions info "$uuid" | sed -n 's/^ *Path: //p' | head -n 1)
fi
if [ ! -f "$ext_dir/schemas/gschemas.compiled" ]; then
  printf '找不到扩展配置。请注销后重新登录，再次运行此脚本。\n' >&2
  exit 1
fi
export GSETTINGS_SCHEMA_DIR="$ext_dir/schemas"
gsettings list-keys "$schema" >/dev/null
mkdir -p -- "$theme_dir"
install -m 644 -- "$script_dir/themes/macos-sky.css" "$theme_dir/macos-sky.css"
install -m 644 -- "$script_dir/themes/macos-sky-dark.css" "$theme_dir/macos-sky-dark.css"
gsettings set "$schema" custom-theme "$theme_dir/macos-sky.css"
gsettings set "$schema" custom-theme-dark "$theme_dir/macos-sky-dark.css"
case "$mode" in
  dark)  gsettings set "$schema" enable-custom-theme false; gsettings set "$schema" enable-custom-theme-dark true ;;
  light) gsettings set "$schema" enable-custom-theme true; gsettings set "$schema" enable-custom-theme-dark false ;;
  auto)  gsettings set "$schema" enable-custom-theme true; gsettings set "$schema" enable-custom-theme-dark true ;;
esac
if gnome-extensions enable "$uuid" 2>/dev/null; then
  printf '云蓝皮肤已安装，模式：%s。\n' "$mode"
else
  printf '皮肤已安装；请注销并重新登录后，在扩展管理器中启用 Customize IBus。\n'
fi
