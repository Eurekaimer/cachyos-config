# 安全与公开边界

[English](../en/security.md)

本仓库是公开的恢复快照，不是密钥备份。采集明确排除密码、SSH/GPG 私钥、云凭据、浏览器资料、Cookie、Clash 配置与订阅、NetworkManager 连接、日志、缓存和 `.omp` 运行状态。

每次发布前必须执行：

```bash
./scripts/audit.sh
```

审计会检查 Shell 语法、禁止出现的私密或运行时路径、疑似密钥文本、逃逸出仓库的符号链接，以及 GitHub 文件大小限制。启发式审计通过只是必要条件；仍需人工检查 `configs/`、`packages/` 和 `state/` 中是否出现未被规则识别的主机名、个人路径、文件名或凭据。

被排除的凭据应保存在密码管理器或加密备份中。不要为了消除采集警告而弱化审计或随意扩大 manifest。
