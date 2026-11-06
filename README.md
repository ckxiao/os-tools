# DSH OS Tools

公开的 Linux 运维脚本菜单。仓库根目录本身就是可发布目录，不依赖构建脚本，也不需要生成 `dist/` 子目录。

## 快速开始

以下命令可直接整段复制执行。

进入交互菜单（推荐，自动下载并按 `SHA256SUMS` 校验）：

```bash
BASE_URL="https://raw.githubusercontent.com/ckxiao/os-tools/main"
bash <(curl -fsSL "$BASE_URL/menu.sh") --set-base-url "$BASE_URL"
```

在本地仓库中运行：

```bash
bash menu.sh
```

非交互安装某个 OS 配置下的全部脚本：

```bash
BASE_URL="https://raw.githubusercontent.com/ckxiao/os-tools/main"
bash <(curl -fsSL "$BASE_URL/menu.sh") \
  --set-base-url "$BASE_URL" \
  --profile ubuntu-24.04 \
  --install-profile
```

按编号运行单个脚本（示例为 `7` 号 `opt.sh`）：

```bash
BASE_URL="https://raw.githubusercontent.com/ckxiao/os-tools/main"
bash <(curl -fsSL "$BASE_URL/menu.sh") \
  --set-base-url "$BASE_URL" \
  --profile ubuntu-24.04 \
  --run 7 -h example -a demo
```

需要 `init-os.sh` 时，把参数接在 `--run 1` 之后：

```bash
BASE_URL="https://raw.githubusercontent.com/ckxiao/os-tools/main"
bash <(curl -fsSL "$BASE_URL/menu.sh") \
  --set-base-url "$BASE_URL" \
  --profile ubuntu-24.04 \
  --run 1 node01 192.168.1.20/24 223.5.5.5
```

## 目录结构

```text
.
├── menu.sh
├── catalog.tsv
├── SHA256SUMS
├── README.md
└── scripts/
    └── ubuntu/
        └── 24.04/
            ├── common.sh
            ├── run.sh
            ├── init-os.sh
            ├── init_docker.sh
            ├── init_llm.sh
            ├── init_dify.sh
            ├── hardening-os.sh
            ├── mgt-god.sh
            └── opt.sh
```

脚本路径统一为：

```text
scripts/<os>/<version>/<script>.sh
```

每个版本目录下有两个非原子脚本：参数中间脚本 `run.sh`（见下文「参数中间脚本」）与共享库 `common.sh`（见下文「共享库」）。两者都不列入 `catalog.tsv`，也不出现在菜单的脚本列表中。

以后增加其他系统时，直接增加版本目录：

```text
scripts/ubuntu/22.04/
scripts/debian/12/
scripts/rocky/9/
scripts/kylin/v10/
```

然后在 [`catalog.tsv`](catalog.tsv) 中增加对应记录。菜单会自动识别新的 OS 配置，不需要改动 `menu.sh`。

## 菜单

在仓库根目录执行 `bash menu.sh`，或使用上文「快速开始」中的在线命令。

交互流程：

1. 主菜单选择操作系统及版本。
2. 二级菜单通过编号选择脚本。
3. 仅在选中脚本后下载对应文件（含该版本的 `run.sh`）。
4. 下载文件必须通过 `SHA256SUMS` 和 `bash -n` 检查。
5. 已安装且校验通过的脚本会直接复用。
6. 脚本所需参数由 `run.sh` 采集与校验，通过后才执行。

二级菜单中的 `96` 可以安装当前 OS 配置下的全部脚本（包含 `run.sh`）。默认单脚本模式不会预下载其他脚本。

## GitHub Raw 使用

静态下载根地址为：

```text
https://raw.githubusercontent.com/ckxiao/os-tools/main
```

不支持进程替代（`<(...)`）的 shell 可以分两步执行：

```bash
BASE_URL="https://raw.githubusercontent.com/ckxiao/os-tools/main"
curl -fsSL "$BASE_URL/menu.sh" -o /tmp/dsh-menu.sh
bash /tmp/dsh-menu.sh --set-base-url "$BASE_URL"
```

重要环境建议把 `BASE_URL` 中的 `main` 换成固定 commit SHA（形如 `https://raw.githubusercontent.com/ckxiao/os-tools/<commit>`），避免上游变更带来不可预期的脚本更新。

## GitHub Pages

仓库根目录已包含全部静态文件，也可直接作为 Pages 发布源。启用后把 `BASE_URL` 换成：

```text
https://ckxiao.github.io/os-tools
```

## 更新脚本

修改任一脚本或目录文件后，需要重新生成根目录校验清单：

```bash
sha256sum menu.sh catalog.tsv README.md scripts/*/*/*.sh > SHA256SUMS
```

`scripts/*/*/*.sh` 已包含各版本的 `run.sh` 与 `common.sh`，无需单独处理。

仓库通过 `.gitattributes` 强制所有文本文件使用 LF 行尾。本仓库在 Windows 上维护、在 Linux 上执行，若检出为 CRLF，`bash` 会因 shebang 失败而无法运行脚本，且 `SHA256SUMS` 校验也会不一致。

GitHub Actions 会检查 Shell 语法、`catalog.tsv` 引用、各版本 `run.sh` 的参数覆盖，以及 `SHA256SUMS` 是否与当前文件一致。

## 参数中间脚本

原子脚本中只有 `init-os.sh` 需要位置参数；其余脚本无位置参数，或按自身语法接收参数（`mgt-god.sh` 为 `函数名 [参数...]`，`opt.sh` 为 `-h/-a` 选项）。

为了把「参数知识」放在与脚本相同的 OS 版本目录内，而不是硬编码进 `menu.sh`，每个版本目录提供一个 `run.sh`：

```bash
bash scripts/ubuntu/24.04/run.sh --list
bash scripts/ubuntu/24.04/run.sh --describe init-os.sh
bash scripts/ubuntu/24.04/run.sh --collect init-os.sh node01 192.168.1.20/24 223.5.5.5
```

`--collect` 校验参数后按「每行一个」输出，供调用方 `mapfile` 读取。退出码约定：

| 退出码 | 含义 |
| --- | --- |
| 0 | 成功 |
| 2 | 用法错误或脚本不存在 |
| 3 | 缺少必填参数 |
| 4 | 参数校验失败 |

`menu.sh` 只负责下载、校验、提权与执行；参数声明、交互提示和格式校验全部委托给 `run.sh`。由于输出写入临时文件而不是进程替换，参数采集失败会正常中断，不会以空参数继续执行。

当前 `ubuntu/24.04` 的参数契约：

| 脚本 | 参数 | 说明 |
| --- | --- | --- |
| `init-os.sh` | `hostname`（必填）、`ip_prefix`（可选）、`dns`（可选） | 位置参数。主机名需符合 RFC 1123；`ip_prefix` 形如 `192.168.1.20/24`，留空沿用当前地址；`dns` 留空使用网关 |
| `hardening-os.sh` | `--ssh-port`、`--allow-hosts`、`--ops-user` | 选项参数。不传 `--allow-hosts` 则不写来源白名单；端口默认 22，运维账号默认 `ck` |
| `init_docker.sh` / `init_llm.sh` / `init_dify.sh` | 无 | 配置项通过环境变量覆盖，见各脚本 `--help` |
| `mgt-god.sh` | 原样透传 | `函数名 [参数...]`，无参进入交互菜单 |
| `opt.sh` | 原样透传 | `-h` / `-a` 示例选项 |

`--collect` 同时接受两种入参形式，输出统一为「每行一个 token」：

```bash
# 位置参数（顺序与契约声明一致）
bash scripts/ubuntu/24.04/run.sh --collect hardening-os.sh 2222 10.0.0.5,10.0.0.6 ops

# 选项参数（可任意顺序，未提供的项取默认值）
bash scripts/ubuntu/24.04/run.sh --collect hardening-os.sh --ssh-port=2222 --ops-user=ops
```

新增 OS 版本时，除了放脚本和登记 `catalog.tsv`，还需提供该版本目录下的 `run.sh`；缺失时 `menu.sh` 会降级为「原始参数直接透传」并给出警告。

## 共享库

`common.sh` 存放被多个原子脚本复用的逻辑，避免同一段代码复制多份：

| 函数 | 作用 |
| --- | --- |
| `init_logging` | 把 stdout/stderr 同时写入 `/var/log/dsh-tools/`，目录不可写时回退当前目录 |
| `green_echo` / `red_echo` / `yellow_echo` | 统一日志输出，非交互终端时自动跳过 sleep |
| `ensure_apt_mirror` | 按 `/etc/os-release` 的代号生成 APT 源并刷新索引 |
| `install_docker` | 安装 Docker CE、配置镜像加速器、把调用者加入 docker 组 |
| `start_stopped_containers` | 启动处于 Exited / Created 状态的容器 |
| `run_step` | 幂等执行：成功后写入 `/var/lib/dsh-tools/state/<name>.done`，重跑自动跳过 |

可覆盖的环境变量：`DSH_TOOLS_APT_MIRROR`、`DSH_TOOLS_DOCKER_REPO`、`DSH_TOOLS_DOCKER_MIRRORS`、`DSH_STATE_DIR`、`DSH_LOG_DIR`；`DSH_TOOLS_FORCE=1` 可忽略状态标记强制重跑。

`common.sh` 不能直接执行（会报错退出），只能被同目录下的脚本 `source`。菜单在下载原子脚本时会一并下载并校验该文件。

## 安全提示

- 公开仓库中的脚本会修改服务器、网络、SSH、Docker 或 Kubernetes。执行前应审查具体脚本及风险说明。
- `hardening-os.sh` 会修改 SSH、PAM 与关键文件权限。脚本已内置两项防锁死措施：关闭密码登录前会检查 root 或 sudo 组用户是否存在 `authorized_keys`，不满足则中止（可用 `HARDENING_ALLOW_NO_KEY=1` 强制）；重启 SSH 前会执行 `sshd -t` 校验配置。即便如此，仍建议先在测试机验证。
- 该脚本的 SSH 来源白名单默认为空，即不做来源限制；需要限制时用 `--allow-hosts="10.0.0.5,10.0.0.6"` 指定。`/etc/hosts.allow` 依赖 sshd 的 libwrap 支持，未编译该特性时不生效，建议同时用 ufw 限制来源。
- 此前版本中 `/etc/shadow` 被设为 `755`、`/tmp` 丢失 sticky bit、`common-account` 规则被误写入 `sshd_config` 等问题已修复。
- `mgt-god.sh` 包含删除、清空、Docker prune、Kubernetes 删除类操作，应以 root 权限严格审核运行。
- `init_llm.sh` 会把 Ollama 的 `11434/TCP` 对外开放，建议增加认证、反向代理、网络 ACL 或限制来源。
- GitHub Raw 和 SHA-256 校验可以保证文件一致性，但仓库维护者账号仍需启用强认证；重要环境应固定 commit SHA，而不是始终使用 `main`。
