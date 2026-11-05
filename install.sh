#!/usr/bin/env bash
set -euo pipefail
usage() { printf '用法：./install.sh [dark|light|auto]\n'; }
mode=${1:-dark}
case "$mode" in dark|light|auto) ;; -h|--help) usage; exit 0 ;; *) usage >&2; exit 2 ;; esac
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
  if [ -d "$backup/rime_ice.userdb" ]; then
    cp -a -- "$backup/rime_ice.userdb" "$stage/"
    printf '保留了目标机器已有的 rime_ice 用户词库；未导入仓库快照。\n'
  fi
fi
if [ ! -d "$stage/rime_ice.userdb" ]; then
  (cd "$stage" && rime_dict_manager -i rime_ice "$src/userdict/rime_ice.txt")
fi
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
