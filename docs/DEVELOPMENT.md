# 开发与验证

本仓库在 Windows 上编辑、在 Linux 上执行。`bash -n` 和单元测试只能覆盖语法与逻辑，
`apt`、`systemctl`、`netplan`、`debconf` 这类行为必须落到真 Linux 上才能验证。

## 环境拓扑

三台机器通过 Tailscale 互联，全部用同一把密钥登录，用户均为 `ck`：

| 节点 | Tailscale 地址 | 角色 | 是否允许装工具 |
| --- | --- | --- | --- |
| `ckagenthost` | 100.64.10.13 | Windows 工作机，编辑代码、发起验证 | — |
| `ckdevpclocal` | 100.64.10.14 | 开发机，Ubuntu 24.04 | **不允许**，只做同步与只读检查 |
| `cku24localtest` | 100.64.10.15 | 测试机，Ubuntu 24.04 | 允许，docker / shellcheck 等装在这里 |

规则很简单：**开发机保持干净**。需要 `apt install`、需要跑容器、需要做破坏性验证时，
一律用 `--test` 走测试机。

## 首次准备

### 1. SSH 别名

`~/.ssh/config` 里配置两个别名，`tools/remote-dev.sh` 默认就用它们：

```sshconfig
Host dsh-dev
    HostName 100.64.10.14
    User ck
    IdentityFile C:/Users/<你>/.ssh/dsh_remote_rsa
    IdentitiesOnly yes

Host dsh-test
    HostName 100.64.10.15
    User ck
    IdentityFile C:/Users/<你>/.ssh/dsh_remote_rsa
    IdentitiesOnly yes
```

Windows 版 ssh 对 `IdentityFile ~/...` 的展开不可靠，建议写绝对路径。

验证：

```bash
ssh dsh-dev 'hostname'
ssh dsh-test 'hostname'
```

### 2. 测试机的 docker

测试机需要能拉镜像。若所在网络不能直连 `registry-1.docker.io`，给守护进程配代理
（docker 守护进程不读 shell 里的 `http_proxy`）：

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/proxy.conf >/dev/null <<'EOF'
[Service]
Environment="HTTP_PROXY=http://<代理>:<端口>"
Environment="HTTPS_PROXY=http://<代理>:<端口>"
Environment="NO_PROXY=localhost,127.0.0.1,100.64.0.0/10,192.168.0.0/16"
EOF
sudo systemctl daemon-reload && sudo systemctl restart docker
```

再把当前用户加入 `docker` 组，避免每次 `sudo`：`sudo usermod -aG docker $USER`。

## 日常命令

```bash
bash tools/remote-dev.sh check          # 测试机：语法 + shellcheck + 单元测试
bash tools/remote-dev.sh check --dev    # 开发机：只跑语法与单测（那里没装 shellcheck）
bash tools/remote-dev.sh container      # 测试机：ubuntu:24.04 容器内跑单元测试
bash tools/remote-dev.sh e2e            # 测试机：容器内跑 debconf 端到端用例
bash tools/remote-dev.sh sync --test    # 只同步
bash tools/remote-dev.sh shell          # 同步后进入开发机交互 shell
bash tools/remote-dev.sh exec --test -- ls -l scripts/ubuntu/24.04
```

同步方式是把工作区打成 tar 经 ssh 送过去，解到远端 `~/dsh-os-tools-dev`，
不依赖 rsync 在本机是否可用。`.git`、`.workbuddy`、`log_*.log` 会被排除。

主机可用环境变量覆盖：`DSH_DEV_HOST`、`DSH_TEST_HOST`、`DSH_REMOTE_DIR`。

## 验证分层

| 层级 | 环境 | 覆盖什么 | 命令 |
| --- | --- | --- | --- |
| 静态 | Windows | 语法、shellcheck、27 个单元用例 | `bash tests/run-tests.sh` |
| 真机 | 测试机 Ubuntu 24.04 | GNU coreutils、bash 5.2、权限与路径行为 | `tools/remote-dev.sh check` |
| 容器 | `ubuntu:24.04` | 干净系统上的运行时行为 | `tools/remote-dev.sh container` |
| 端到端 | `ubuntu:24.04` + pty | debconf 不弹框、preseed 生效 | `tools/remote-dev.sh e2e` |
| CI | GitHub Actions | 以上静态项 + e2e 容器任务 | push 后自动 |

`tests/e2e-debconf.sh` 用 `script -qec` 在容器里造一个 pty，因为 debconf 只有在有终端时
才会真正弹框——没有 pty 的测试会假通过。

## 排错

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `无法连接 dsh-test` | Tailscale 掉线或密钥路径错 | `tailscale status`、`ssh -v dsh-test true` |
| 容器拉镜像 `i/o timeout` | 守护进程没走代理 | 配 `docker.service.d/proxy.conf` 并重启 docker |
| `permission denied ... docker.sock` | 用户不在 docker 组 | `sudo usermod -aG docker $USER`，重新登录 |
| 同步后在远端看不到新文件 | 同步到了另一台 | `sync --test` 与命令的 `--test` 要一致 |
