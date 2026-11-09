#!/usr/bin/env bash
set -euo pipefail
usage() { printf '用法：./install.sh [spring|dark|light|auto]\n'; }
mode=${1:-spring}
case "$mode" in spring|dark|light|auto) ;; -h|--help) usage; exit 0 ;; *) usage >&2; exit 2 ;; esac
[ "$#" -le 1 ] || { usage >&2; exit 2; }
src=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
"$src/install-deps.sh" all
for cmd in rime_deployer rime_dict_manager ibus python3; do
  command -v "$cmd" >/dev/null || { printf '缺少 %s，请先安装 ibus-rime、rime-data 和 Python 3。\n' "$cmd" >&2; exit 1; }
done
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
target=${IBUS_RIME_DIR:-$config_home/ibus/rime}
parent=$(dirname -- "$target")
shared=${RIME_SHARED_DATA_DIR:-/usr/share/rime-data}
[ -f "$shared/ibus_rime.yaml" ] || { printf '未找到 IBus Rime 系统配置：%s\n' "$shared/ibus_rime.yaml" >&2; exit 1; }
[ -f "$src/userdict/rime_ice.txt" ] || { printf '未找到用户词库备份。\n' >&2; exit 1; }
mkdir -p -- "$parent"
stage=$(mktemp -d "$parent/.rime-install.XXXXXXXX")
backup=''
started=0
installed=0
cleanup() {
  status=$?
  if [ "$status" -ne 0 ] && [ "$installed" -eq 0 ] && [ -n "$backup" ] && [ -e "$backup" ] && [ ! -e "$target" ]; then
    mv -- "$backup" "$target" || printf '恢复原配置失败，请手动恢复 %s。\n' "$backup" >&2
  fi
  if [ "$started" -eq 1 ]; then
    ibus-daemon --daemonize --replace --xim --panel disable || printf '请手动重启 IBus。\n' >&2
  fi
  if [ -d "$stage" ]; then printf '临时目录保留在 %s\n' "$stage" >&2; fi
  exit "$status"
}
trap cleanup EXIT
cp -a -- "$src/rime/." "$stage/"
# 基础词库以压缩分片保存在仓库，部署前还原并校验原始内容。
cat -- "$src"/data/wanxiang-jichu.yaml.gz.part{00,01,02,03} | gzip -dc > "$stage/dicts/jichu.dict.yaml"
printf '%s  %s\n' '1e03f4c3aa634f9320d50bd660833d2d3a855793fcface30b1509d75409c52bc' "$stage/dicts/jichu.dict.yaml" | sha256sum -c --status || { printf '万象基础词库校验失败。\n' >&2; exit 1; }
# 万象模型超过 GitHub 普通文件限制，通过官方 LTS 下载并校验固定版本。
model_name=wanxiang-lts-zh-hans.gram
model_sha=769854c83f6c914a05a1e1abb67c31c00f1ae622a41878e05957bcdee3dbda9a
model_cache="${XDG_CACHE_HOME:-$HOME/.cache}/ibus-rime"
model_source=${RIME_WANXIANG_MODEL:-$model_cache/$model_name}
if [ ! -f "$model_source" ]; then
  if [ -n "${RIME_WANXIANG_MODEL:-}" ]; then
    printf '指定的万象模型不存在：%s\n' "$model_source" >&2; exit 1
  fi
  mkdir -p -- "$model_cache"
  download_tmp=$(mktemp "$model_cache/.wanxiang-download.XXXXXXXX")
  if ! curl -fL --retry 2 --connect-timeout 20 -o "$download_tmp" "https://github.com/amzxyz/rime-wanxiang-data/releases/download/LTS/$model_name"; then
    printf '模型下载失败，临时文件保存在 %s。\n' "$download_tmp" >&2; exit 1
  fi
  if ! printf '%s  %s\n' "$model_sha" "$download_tmp" | sha256sum -c --status; then
    printf '模型校验失败，临时文件保存在 %s。上游 LTS 可能已更新。\n' "$download_tmp" >&2; exit 1
  fi
  mv -- "$download_tmp" "$model_source"
fi
if ! printf '%s  %s\n' "$model_sha" "$model_source" | sha256sum -c --status; then
  printf '模型校验失败：%s。请提供与仓库版本匹配的模型。\n' "$model_source" >&2; exit 1
fi
cp --reflink=auto -- "$model_source" "$stage/$model_name"
# 一些 Rime 自带的忽略规则不影响目录复制，但不复制 Git 数据。
rime_deployer --build "$stage" "$shared" "$stage/build"
# rime_deployer --build 不部署前端的 ibus_rime.yaml；单独生成部署结果。
# 用户补丁保留在 ibus_rime.custom.yaml，可由 Rime 常规部署重新应用。
python3 - "$shared/ibus_rime.yaml" "$stage/build/ibus_rime.yaml" <<'PY'
import re, sys
from pathlib import Path
shared = Path(sys.argv[1]).read_text(encoding='utf-8')
m = re.search(r'(?m)^config_version:\s*["\']?([^\s"\']+)', shared)
if not m:
    raise SystemExit('无法读取 ibus_rime.yaml 的 config_version')
Path(sys.argv[2]).write_text("config_version: '" + m.group(1) + "'\nstyle:\n  horizontal: true\n  inline_preedit: true\n  preedit_style: composition\n  cursor_type: insert\n", encoding='utf-8')
PY
if [ "${IBUS_SKY_TEST_NO_RESTART:-0}" != 1 ]; then
  ibus exit || true
  started=1
fi
# 先保留完整旧目录。用户词库需要 IBus 停止后才能安全复制。
if [ -e "$target" ]; then
  backup="$parent/rime.backup.$(date +%Y%m%d-%H%M%S).$$"
  mv -- "$target" "$backup"
  for dict in rime_ice wanxiang en sequence stats; do
    if [ -d "$backup/$dict.userdb" ]; then
      cp -a -- "$backup/$dict.userdb" "$stage/"
      printf '保留目标机器已有的 %s 用户数据库。\n' "$dict"
    fi
  done
fi
for dict in rime_ice wanxiang en; do
  if [ ! -d "$stage/$dict.userdb" ] && [ -f "$src/userdict/$dict.txt" ]; then
    (cd "$stage" && rime_dict_manager -i "$dict" "$src/userdict/$dict.txt")
  fi
done
# 在新环境默认进入雾凇小鹤双拼，保留全拼与万象作为可切换方案。
(cd "$stage" && rime_deployer --set-active-schema double_pinyin_flypy)
mv -- "$stage" "$target"
installed=1
[ -z "$backup" ] || printf '原 Rime 数据已备份：%s\n' "$backup"
# 尽早恢复输入法；若主题安装失败，Rime 仍可使用。
if [ "$started" -eq 1 ]; then
  ibus-daemon --daemonize --replace --xim --panel disable
  started=0
fi
"$src/install-theme.sh" "$mode"
printf 'Rime 配置、词库和皮肤已安装到 %s。\n' "$target"
