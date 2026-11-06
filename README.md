# DSH OS Tools

公开的 Linux 运维脚本菜单。仓库根目录本身就是可发布目录，不依赖构建脚本，也不需要生成 `dist/` 子目录。

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

以后增加其他系统时，直接增加版本目录：

```text
scripts/ubuntu/22.04/
scripts/debian/12/
scripts/rocky/9/
scripts/kylin/v10/
```

然后在 [`catalog.tsv`](catalog.tsv) 中增加对应记录。菜单会自动识别新的 OS 配置，不需要改动 `menu.sh`。

## 菜单

在本地仓库运行：

```bash
bash menu.sh
```

交互流程：

1. 主菜单选择操作系统及版本。
2. 二级菜单通过编号选择脚本。
3. 仅在选中脚本后下载对应文件。
4. 下载文件必须通过 `SHA256SUMS` 和 `bash -n` 检查。
5. 已安装且校验通过的脚本会直接复用。

二级菜单中的 `96` 可以安装当前 OS 配置下的全部脚本。默认单脚本模式不会预下载其他脚本。

## GitHub Raw 使用

假设仓库地址为：

```text
https://github.com/ckxiao/os-tools
```

则静态下载根地址为：

```text
https://raw.githubusercontent.com/ckxiao/os-tools/main
```

下载并运行菜单：

```bash
BASE_URL="https://raw.githubusercontent.com/ckxiao/os-tools/main"
curl -fsSL "$BASE_URL/menu.sh" -o /tmp/dsh-menu.sh
bash /tmp/dsh-menu.sh --set-base-url "$BASE_URL"
```

使用进程替代的便捷方式：

```bash
BASE_URL="https://raw.githubusercontent.com/ckxiao/os-tools/main"
bash <(curl -fsSL "$BASE_URL/menu.sh") --set-base-url "$BASE_URL"
```

非交互安装 Ubuntu 24.04 下的全部脚本：

```bash
BASE_URL="https://raw.githubusercontent.com/ckxiao/os-tools/main"
bash <(curl -fsSL "$BASE_URL/menu.sh") \
  --set-base-url "$BASE_URL" \
  --profile ubuntu-24.04 \
  --install-profile
```

按需运行单个脚本：

```bash
BASE_URL="https://raw.githubusercontent.com/ckxiao/os-tools/main"
bash <(curl -fsSL "$BASE_URL/menu.sh") \
  --set-base-url "$BASE_URL" \
  --profile ubuntu-24.04 \
  --run 7 -h example -a demo
```

## GitHub Pages

因为根目录已经包含全部静态文件，也可以把仓库根目录直接作为 GitHub Pages 发布源：

```text
https://ckxiao.github.io/os-tools
```

启用 Pages 后，命令形式为：

```bash
BASE_URL="https://ckxiao.github.io/os-tools"
curl -fsSL "$BASE_URL/menu.sh" -o /tmp/dsh-menu.sh
bash /tmp/dsh-menu.sh --set-base-url "$BASE_URL"
```

## 更新脚本

修改任一脚本或目录文件后，需要重新生成根目录校验清单：

```bash
sha256sum menu.sh catalog.tsv README.md scripts/*/*/*.sh > SHA256SUMS
```

GitHub Actions 会检查 Shell 语法、目录引用以及 `SHA256SUMS` 是否与当前文件一致。

## 安全提示

- 公开仓库中的脚本会修改服务器、网络、SSH、Docker 或 Kubernetes。执行前应审查具体脚本及风险说明。
- `hardening-os.sh` 当前存在严重问题：会把 `/etc/shadow` 设置为 `755`、移除 `/tmp` 的 sticky bit，并可能造成 SSH 登录锁定。生产使用前必须修复。
- `mgt-god.sh` 包含删除、清空、Docker prune、Kubernetes 删除类操作，应以 root 权限严格审核运行。
- `init_llm.sh` 会把 Ollama 的 `11434/TCP` 对外开放，建议增加认证、反向代理、网络 ACL 或限制来源。
- GitHub Raw 和 SHA-256 校验可以保证文件一致性，但仓库维护者账号仍需启用强认证；重要环境应固定 commit SHA，而不是始终使用 `main`。
