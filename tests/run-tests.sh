#!/usr/bin/env bash
#
# 零依赖测试运行器：不依赖 bats，Windows(Git Bash) 与 Linux 均可执行。
#
# 用法：
#   bash tests/run-tests.sh            # 运行全部用例
#   bash tests/run-tests.sh collect    # 只运行名称包含 collect 的用例
#
# 约定：函数名以 test_ 开头的即一个用例；用例在独立子 shell 中执行。

set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$ROOT/scripts/ubuntu/24.04/run.sh"
MENU="$ROOT/menu.sh"
COMMON="$ROOT/scripts/ubuntu/24.04/common.sh"
CATALOG="$ROOT/catalog.tsv"

export DSH_LOG_SLEEP=0

PASS=0
FAIL=0
FAILED=()

# ---------------------------------------------------------------- 断言

assert_contains() {
    local haystack="$1" needle="$2"
    [[ "$haystack" == *"$needle"* ]] || {
        echo "    期望包含：$needle"
        echo "    实际输出：$(printf '%s' "$haystack" | head -c 300)"
        return 1
    }
}

assert_not_contains() {
    local haystack="$1" needle="$2"
    [[ "$haystack" != *"$needle"* ]] || {
        echo "    不应包含：$needle"
        return 1
    }
}

assert_eq() {
    local expected="$1" actual="$2"
    [ "$expected" = "$actual" ] || {
        echo "    期望：[$expected]"
        echo "    实际：[$actual]"
        return 1
    }
}

assert_status() {
    local expected="$1" actual="$2"
    [ "$expected" -eq "$actual" ] || {
        echo "    期望退出码：$expected，实际：$actual"
        echo "    输出：$(printf '%s' "$OUTPUT" | head -c 300)"
        return 1
    }
}

assert_empty() {
    [ -z "$1" ] || {
        echo "    期望输出为空，实际：$(printf '%s' "$1" | head -c 200)"
        return 1
    }
}

assert_file_exists() {
    [ -f "$1" ] || {
        echo "    文件不存在：$1"
        return 1
    }
}

# 执行命令并记录 stdout+stderr 与退出码；stdin 固定为 /dev/null
run_cmd() {
    OUTPUT="$("$@" 2>&1 </dev/null)"
    RC=$?
}

# ---------------------------------------------------------------- 用例

test_run_list_excludes_helpers() {
    run_cmd bash "$RUNNER" --list
    assert_status 0 "$RC" &&
        assert_contains "$OUTPUT" "init-os.sh" &&
        assert_contains "$OUTPUT" "hardening-os.sh" &&
        assert_not_contains "$OUTPUT" "run.sh" &&
        assert_not_contains "$OUTPUT" "common.sh"
}

test_describe_shows_flags() {
    run_cmd bash "$RUNNER" --describe hardening-os.sh
    assert_status 0 "$RC" &&
        assert_contains "$OUTPUT" "--ssh-port" &&
        assert_contains "$OUTPUT" "--allow-hosts" &&
        assert_contains "$OUTPUT" "--ops-user"
}

test_collect_initos_positional() {
    run_cmd bash "$RUNNER" --collect init-os.sh node01 192.168.1.20/24 223.5.5.5
    assert_status 0 "$RC" || return 1
    assert_eq "node01" "$(sed -n 1p <<<"$OUTPUT")" &&
        assert_eq "192.168.1.20/24" "$(sed -n 2p <<<"$OUTPUT")" &&
        assert_eq "223.5.5.5" "$(sed -n 3p <<<"$OUTPUT")"
}

test_collect_fills_defaults() {
    # 所有参数都有默认值：不给任何入参也应成功，并逐项输出
    local tmp
    tmp="$(mktemp -d)"
    bash "$RUNNER" --collect init-os.sh >"$tmp/out" 2>&1 </dev/null
    RC=$?
    OUTPUT="$(cat "$tmp/out")"
    local lines
    lines="$(wc -l <"$tmp/out")"
    rm -rf "$tmp" 2>/dev/null || true
    assert_status 0 "$RC" || return 1
    assert_eq "3" "$lines" &&
        [ -n "$(sed -n 1p <<<"$OUTPUT")" ] || {
        echo "    hostname 默认值不应为空"
        return 1
    }
}

test_collect_invalid_values() {
    run_cmd bash "$RUNNER" --collect init-os.sh "bad_host" "" ""
    assert_status 4 "$RC" || return 1

    run_cmd bash "$RUNNER" --collect init-os.sh node01 "192.168.1.300/24" ""
    assert_status 4 "$RC" || return 1

    run_cmd bash "$RUNNER" --collect hardening-os.sh --ssh-port=70000
    assert_status 4 "$RC"
}

test_collect_flag_form() {
    run_cmd bash "$RUNNER" --collect hardening-os.sh --ssh-port=2222 --ops-user=ops
    assert_status 0 "$RC" &&
        assert_contains "$OUTPUT" "--ssh-port=2222" &&
        assert_contains "$OUTPUT" "--ops-user=ops"
}

test_collect_passthrough() {
    run_cmd bash "$RUNNER" --collect mgt-god.sh check_disk_usage
    assert_status 0 "$RC" && assert_eq "check_disk_usage" "$OUTPUT"
}

test_collect_no_args_emits_nothing() {
    run_cmd bash "$RUNNER" --collect init_docker.sh
    assert_status 0 "$RC" && assert_empty "$OUTPUT"
}

test_runner_unknown_command() {
    run_cmd bash "$RUNNER" --bogus
    assert_status 2 "$RC"
}

test_common_refuses_direct_execution() {
    run_cmd bash "$COMMON"
    assert_status 1 "$RC" && assert_contains "$OUTPUT" "共享库"
}

test_menu_version() {
    run_cmd bash "$MENU" --version
    assert_status 0 "$RC" && assert_contains "$OUTPUT" "dsh-os-tools"
}

test_menu_list_profiles() {
    run_cmd bash "$MENU" --list
    assert_status 0 "$RC" &&
        assert_contains "$OUTPUT" "ubuntu-24.04" &&
        assert_contains "$OUTPUT" "init-os.sh" &&
        assert_contains "$OUTPUT" "mgt-god.sh"
}

test_menu_unknown_option() {
    run_cmd bash "$MENU" --nope
    [ "$RC" -ne 0 ] || {
        echo "    未知参数应返回非零"
        return 1
    }
    assert_contains "$OUTPUT" "未知参数"
}

test_hardening_help() {
    run_cmd bash "$ROOT/scripts/ubuntu/24.04/hardening-os.sh" --help
    assert_status 0 "$RC" &&
        assert_contains "$OUTPUT" "--ssh-port" &&
        assert_contains "$OUTPUT" "--allow-hosts"
}

test_catalog_has_twelve_fields() {
    local line count
    while IFS= read -r line; do
        [[ -z "${line//[[:space:]]/}" || "$line" == \#* ]] && continue
        count="$(awk -F'|' '{print NF}' <<<"$line")"
        [ "$count" -eq 12 ] || {
            echo "    字段数应为 12，实际 $count：$line"
            return 1
        }
    done <"$CATALOG"
    return 0
}

test_catalog_references_exist() {
    local pid _f _v os_path _t _sid file rest
    while IFS='|' read -r pid _f _v os_path _t _sid file rest; do
        [[ -z "${pid//[[:space:]]/}" || "$pid" == \#* ]] && continue
        assert_file_exists "$ROOT/scripts/$os_path/$file" || return 1
        assert_file_exists "$ROOT/scripts/$os_path/run.sh" || return 1
    done <"$CATALOG"
    return 0
}

test_extra_files_declared_in_menu_exist() {
    local line extras extra os_path
    line="$(grep -m1 '^readonly EXTRA_FILES=' "$MENU")" || {
        echo "    menu.sh 中未找到 EXTRA_FILES 声明"
        return 1
    }
    extras="$(sed -E 's/^readonly EXTRA_FILES=\((.*)\)$/\1/' <<<"$line" | tr -d '"')"

    while IFS='|' read -r _pid _f _v os_path _t _sid _file _rest; do
        [[ -z "${_pid//[[:space:]]/}" || "$_pid" == \#* ]] && continue
        for extra in $extras; do
            assert_file_exists "$ROOT/scripts/$os_path/$extra" || return 1
        done
    done <"$CATALOG"
    return 0
}

test_scripts_syntax() {
    local f
    for f in "$MENU" "$ROOT"/scripts/*/*/*.sh; do
        bash -n "$f" || {
            echo "    语法检查失败：$f"
            return 1
        }
    done
    return 0
}

test_mirror_probe_filters_dead_entries() {
    local shim
    shim="$(mktemp -d)"
    cat >"$shim/curl" <<'SHIM'
#!/usr/bin/env bash
url="${!#}"
case "$url" in
*alive*) printf '200' ;;
*) printf '000' ;;
esac
SHIM
    chmod +x "$shim/curl"

    local out
    out="$(
        PATH="$shim:$PATH" DSH_TOOLS_DOCKER_MIRRORS="https://alive.example,https://dead.example" \
            bash -c '. "$1"; probe_docker_mirrors >/dev/null 2>&1; printf "RESULT:%s" "${REACHABLE_DOCKER_MIRRORS:-}"' test "$COMMON"
    )"
    rm -rf "$shim"

    assert_eq "RESULT:https://alive.example" "$out"
}

test_menu_is_sourceable() {
    run_cmd bash -c 'source "$1"' _ "$MENU"
    assert_status 0 "$RC" && assert_empty "$OUTPUT"
}

test_manifest_pin_accepts_match_and_rejects_mismatch() {
    local tmp manifest good
    tmp="$(mktemp -d)"
    manifest="$tmp/SHA256SUMS"
    printf 'dummy\n' >"$manifest"
    good="$(sha256sum "$manifest" | awk '{print $1}' | sed 's/^\\//')"

    run_cmd bash -c 'source "$1"; DSH_TOOLS_EXPECTED_SHA256="$2" verify_manifest_pin "$3"' \
        _ "$MENU" "$good" "$manifest"
    if ! assert_status 0 "$RC"; then
        rm -rf "$tmp"
        return 1
    fi

    run_cmd bash -c 'source "$1"; DSH_TOOLS_EXPECTED_SHA256=deadbeef verify_manifest_pin "$2"' \
        _ "$MENU" "$manifest"
    local bad_rc=$RC
    rm -rf "$tmp"

    [ "$bad_rc" -ne 0 ] || {
        echo "    哈希不一致时应返回非零，实际 $bad_rc"
        return 1
    }
    return 0
}

test_signature_check_disabled_by_default() {
    local tmp manifest
    tmp="$(mktemp -d)"
    manifest="$tmp/SHA256SUMS"
    printf 'dummy\n' >"$manifest"

    run_cmd bash -c 'source "$1"; verify_manifest_signature "$2"' _ "$MENU" "$manifest"
    local rc=$?
    rm -rf "$tmp"
    assert_status 0 "$rc"
}

test_apt_get_sets_noninteractive_env() {
    local shim out
    shim="$(mktemp -d)"
    cat >"$shim/sudo" <<'SHIM'
#!/usr/bin/env bash
exec "$@"
SHIM
    cat >"$shim/apt-get" <<'SHIM'
#!/usr/bin/env bash
printf 'FE=%s ARGS=%s\n' "$DEBIAN_FRONTEND" "$*"
SHIM
    chmod +x "$shim/sudo" "$shim/apt-get"

    out="$(PATH="$shim:$PATH" bash -c '. "$1"; apt_get install -y foo' test "$COMMON" 2>&1)"
    rm -rf "$shim"

    assert_contains "$out" "FE=noninteractive" &&
        assert_contains "$out" "install -y foo" &&
        assert_contains "$out" "--force-confold"
}

test_modules_use_apt_get_wrapper() {
    local f hits="" h
    for f in "$ROOT"/scripts/ubuntu/24.04/{mgt-god,users,network,service,container,k8s}.sh; do
        [ -f "$f" ] || continue
        h="$(grep -nE '(^|[^_[:alnum:]])apt(-get)? (install|update|upgrade|purge)' "$f" |
            grep -v 'apt_get' | grep -vE '^[0-9]+:[[:space:]]*#' || true)"
        [ -n "$h" ] && hits+="$f: $h"$'\n'
    done
    if [ -n "$hits" ]; then
        echo "    发现未走 apt_get 的裸调用："
        printf '%s' "$hits"
        return 1
    fi
    return 0
}

test_no_unquoted_test_operands() {
    local f hits="" h
    for f in "$MENU" "$ROOT"/scripts/*/*/*.sh; do
        [ -f "$f" ] || continue
        # [ $var = x ] / [ -z $var ] 在变量为空或含空格时会退化成语法错误
        h="$(grep -nE '\[ (\$[A-Za-z_][A-Za-z0-9_]*|-[nz] \$[A-Za-z_][A-Za-z0-9_]*) (=|!=|==|\])' "$f" |
            grep -v '\[\[' || true)"
        [ -n "$h" ] && hits+="$f: $h"$'\n'
    done
    if [ -n "$hits" ]; then
        echo "    发现未加引号的测试操作数："
        printf '%s' "$hits"
        return 1
    fi
    return 0
}

test_sha256_file_strips_escape_prefix() {
    local shim out want
    want="abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
    shim="$(mktemp -d)"
    # 模拟 GNU coreutils 在文件名含反斜杠(Windows 路径)时给整行加 '\' 的行为
    cat >"$shim/sha256sum" <<SHIM
#!/usr/bin/env bash
printf '\\\\${want} *file\n'
SHIM
    chmod +x "$shim/sha256sum"

    out="$(PATH="$shim:$PATH" bash -c '. "$1"; sha256_file /tmp/whatever' test "$MENU" 2>&1)"
    rm -rf "$shim"

    assert_eq "$want" "$out"
}

test_catalog_dedupes_multiple_profiles() {
    local tmp catalog out
    tmp="$(mktemp -d)"
    catalog="$tmp/catalog.tsv"
    cat >"$catalog" <<'TSV'
# profile_id|os_family|os_version|os_path|profile_title|script_id|filename|script_title|description|risk|requires_root|argument_mode
ubuntu-24.04|Ubuntu|24.04|ubuntu/24.04|Ubuntu 24.04 LTS|1|init-os.sh|基础初始化|d|r|yes|prompt
ubuntu-24.04|Ubuntu|24.04|ubuntu/24.04|Ubuntu 24.04 LTS|2|init_docker.sh|Docker|d|r|yes|none
debian-12|Debian|12|debian/12|Debian 12|1|init-os.sh|基础初始化|d|r|yes|prompt
debian-12|Debian|12|debian/12|Debian 12|2|init_docker.sh|Docker|d|r|yes|none
TSV

    # IFS 含换行时曾导致 PROFILE_IDS 重复累加，这里直接验证去重结果
    out="$(bash -c '. "$1"; load_catalog_file "$2"; printf "%s\n" "${PROFILE_IDS[@]}"' test "$MENU" "$catalog" 2>&1)"
    rm -rf "$tmp"

    assert_eq "ubuntu-24.04
debian-12" "$out"
}

test_explain_emits_metadata() {
    run_cmd bash "$RUNNER" --explain hardening-os.sh
    assert_status 0 "$RC" || return 1
    assert_contains "$OUTPUT" "ssh-port" &&
        assert_contains "$OUTPUT" "allow-hosts" || return 1
    # 每行必须恰好 5 列（4 个 0x1f 分隔符），否则 menu 会错列
    local bad
    bad="$(printf '%s\n' "$OUTPUT" | awk -F'\037' 'NF!=5' | wc -l)"
    assert_eq "0" "$bad"
}

test_explain_applies_overrides() {
    run_cmd bash "$RUNNER" --explain init-os.sh node01 10.0.0.5/24 1.1.1.1
    assert_status 0 "$RC" &&
        assert_contains "$OUTPUT" "node01" &&
        assert_contains "$OUTPUT" "10.0.0.5/24" &&
        assert_contains "$OUTPUT" "1.1.1.1"
}

test_review_loop_edits_value() {
    local tmp
    tmp="$(mktemp -d)"
    cat >"$tmp/drive.sh" <<'DRIVE'
set -uo pipefail
. "$1"
trap - EXIT          # 去掉 menu.sh 的清理 trap，避免它影响退出码
WORK_DIR="$2"
review_script_args "$3" init-os.sh
printf 'RESULT:%s\n' "${REVIEW_ARGS[*]}"
DRIVE
    OUTPUT="$(printf '1\nnode77\n\n' | bash "$tmp/drive.sh" "$MENU" "$tmp" "$RUNNER" 2>&1)"
    RC=$?
    rm -rf "$tmp" 2>/dev/null || true
    assert_status 0 "$RC" &&
        assert_contains "$OUTPUT" "当前参数" &&
        assert_contains "$OUTPUT" "RESULT:node77"
}

test_review_loop_cancel() {
    local tmp
    tmp="$(mktemp -d)"
    cat >"$tmp/drive.sh" <<'DRIVE'
set -uo pipefail
. "$1"
trap - EXIT
WORK_DIR="$2"
if review_script_args "$3" init-os.sh; then
    echo "RESULT:accepted"
else
    echo "RESULT:cancelled"
fi
DRIVE
    OUTPUT="$(printf 'q\n' | bash "$tmp/drive.sh" "$MENU" "$tmp" "$RUNNER" 2>&1)"
    RC=$?
    rm -rf "$tmp" 2>/dev/null || true
    assert_status 0 "$RC" && assert_contains "$OUTPUT" "RESULT:cancelled"
}

# ---------------------------------------------------------------- 运行

main() {
    local filter="${1:-}"
    local name

    echo "仓库根目录：$ROOT"
    echo ""

    while read -r name; do
        [ -n "$name" ] || continue
        if [ -n "$filter" ] && [[ "$name" != *"$filter"* ]]; then
            continue
        fi

        if ( set -uo pipefail; "$name" ); then
            printf '  ok   %s\n' "${name#test_}"
            PASS=$((PASS + 1))
        else
            printf '  FAIL %s\n' "${name#test_}"
            FAIL=$((FAIL + 1))
            FAILED+=("${name#test_}")
        fi
    done < <(declare -F | awk '{print $3}' | grep '^test_' | sort)

    echo ""
    echo "通过 $PASS 个，失败 $FAIL 个"
    if [ "$FAIL" -gt 0 ]; then
        echo "失败用例：${FAILED[*]}"
        return 1
    fi
    return 0
}

main "$@"
