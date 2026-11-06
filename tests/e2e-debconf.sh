#!/usr/bin/env bash
#
# debconf 非交互验证：在真实 Ubuntu 24.04（容器或测试机）里确认
# 升级/安装 keyboard-configuration、console-setup 时不会弹出选择界面。
#
#   bash tests/e2e-debconf.sh
#
# 需要 root（容器内默认是 root）。会执行 apt-get update 与真实安装，
# 因此只在一次性环境（容器 / 测试机）里跑，不要在开发机上跑。

set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
INIT_OS="$ROOT/scripts/ubuntu/24.04/init-os.sh"
TIMEOUT_SEC="${E2E_TIMEOUT:-300}"

PASS=0
FAIL=0

ok() {
    printf '  ok   %s\n' "$1"
    PASS=$((PASS + 1))
}

bad() {
    printf '  FAIL %s\n' "$1"
    [ -n "${2:-}" ] && printf '       %s\n' "$2"
    FAIL=$((FAIL + 1))
}

if [ "$(id -u)" -ne 0 ]; then
    echo "需要 root 执行（容器内默认满足）" >&2
    exit 2
fi

command -v debconf-set-selections >/dev/null 2>&1 || {
    echo "缺少 debconf-set-selections，先 apt-get install -y debconf" >&2
    exit 2
}

echo "== 环境 =="
grep PRETTY /etc/os-release
echo "  bash $BASH_VERSION"

echo ""
echo "== 1. 从 init-os.sh 抽取 preseed =="
# 直接取脚本里那段 heredoc，避免与实现各写一份而漂移
PRESEED="$(
    awk '/<<.PRESEED.$/{flag=1; next} /^PRESEED$/{flag=0} flag' "$INIT_OS"
)"
if [ -z "$PRESEED" ]; then
    bad "preseed 抽取" "init-os.sh 中没有找到 PRESEED 段"
else
    ok "preseed 抽取（$(printf '%s' "$PRESEED" | wc -l) 行）"
    printf '%s\n' "$PRESEED" | sed 's/^/       /'
    printf '%s\n' "$PRESEED" | debconf-set-selections &&
        ok "debconf-set-selections 接受该 preseed" ||
        bad "debconf-set-selections 拒绝该 preseed"
fi

echo ""
echo "== 2. 非交互安装 keyboard-configuration / console-setup =="
apt-get update -qq >/dev/null 2>&1 || bad "apt-get update"

start=$(date +%s)
DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    APT_LISTCHANGES_FRONTEND=none \
    NEEDRESTART_MODE=a \
    timeout "$TIMEOUT_SEC" apt-get install -y -qq \
    -o Dpkg::Options::=--force-confdef \
    -o Dpkg::Options::=--force-confold \
    keyboard-configuration console-setup </dev/null >/tmp/e2e-apt.log 2>&1
rc=$?
elapsed=$(($(date +%s) - start))

if [ "$rc" -eq 0 ]; then
    ok "安装完成，未阻塞（${elapsed}s）"
elif [ "$rc" -eq 124 ]; then
    bad "安装超时 ${TIMEOUT_SEC}s" "说明仍在等待交互，检查 preseed 是否生效"
else
    bad "安装失败 rc=$rc" "$(tail -3 /tmp/e2e-apt.log | tr '\n' ' ')"
fi

echo ""
echo "== 3. 预置值是否真的生效 =="
layout="$(debconf-show keyboard-configuration 2>/dev/null | sed -n 's/.*layoutcode: *//p' | head -1)"
model="$(debconf-show keyboard-configuration 2>/dev/null | sed -n 's/.*modelcode: *//p' | head -1)"
[ "$layout" = "us" ] && ok "layoutcode = us" || bad "layoutcode" "实际：[$layout]"
[ "$model" = "pc105" ] && ok "modelcode = pc105" || bad "modelcode" "实际：[$model]"

echo ""
echo "通过 $PASS 个，失败 $FAIL 个"
[ "$FAIL" -eq 0 ]
