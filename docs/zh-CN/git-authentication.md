# Git 免密推送（GitHub）

[English](../en/git-authentication.md)

发布快照（`capture.sh` → `git commit` → `git push`）需要免密向 GitHub 推送。
本机当前状态：`https` + GitHub CLI（`gh`）认证，token 保存在系统 keyring，
无 SSH key。下面两种方案二选一。

## 方案 A：SSH key（推荐，跨机最干净）

不依赖 keyring 和 gh 登录状态，适合「桌面 + 笔记本」多机同步。

```sh
# 1) 生成密钥（无密码短语，push 才真正免密；可以加，但每次 push 要输）
ssh-keygen -t ed25519 -C "eurekaimer@github" -f ~/.ssh/id_ed25519

# 2) 把公钥加入 GitHub 账号（二选一）
gh ssh-key add ~/.ssh/id_ed25519.pub --title "komari"
#    或浏览器打开 https://github.com/settings/keys → New SSH key 粘贴公钥

# 3) 把仓库 remote 从 https 改成 ssh
git -C ~/Documents/GitHub/cachyos-config remote set-url origin git@github.com:Eurekaimer/cachyos-config.git

# 4) 验证（首次会询问 known_hosts，输入 yes）
ssh -T git@github.com
#    成功输出: Hi Eurekaimer! You've successfully authenticated...

# 5) 此后 git push 不再要任何凭据
```

## 方案 B：https + GitHub CLI（现状）

靠 gh 的 token（keyring 中）提供 git 凭据，无需每推输入。

```sh
gh auth login        # 选 GitHub.com → HTTPS → 浏览器登录
gh auth setup-git    # 让 git 使用 gh 作为 credential helper
gh auth status       # 确认 Logged in + Git operations protocol: https
```

依赖 keyring：新机器/新登录需重新 `gh auth login`。

## 多机共用的两种做法

- **各生成一把 key，都加入同一 GitHub 账号**（推荐）：私钥不出本机，
  哪台掉了删哪把，能精确吊销。
- **单把 key 复制到多台**：把 `~/.ssh/id_ed25519`（及 `.pub`）复制到另一台
  的 `~/.ssh/`，然后 `chmod 600 ~/.ssh/id_ed25519`。任意一台换 key 都要
  回 GitHub 更新。

## 故障排查

| 现象 | 处理 |
| --- | --- |
| `Permission denied (publickey)` | 跑 `ssh -T git@github.com`，看被识别为哪个账号；key 未加/加错账号 |
| 多把 key 或换了新 key | 在 `~/.ssh/config` 写明 `Host github.com` + `IdentityFile ~/.ssh/<key>`，并用 `ssh-add -D` 清掉 ssh-agent 里的旧 key |
| `known_hosts` 被误改 | 删掉 `~/.ssh/known_hosts` 里 github.com 行再重试（会重新提示信任） |

## 仅用于 Git 也能用于 SSH 登录

这把 key（`~/.ssh/id_ed25519.pub`）同样可以加进其它机器的
`~/.ssh/authorized_keys`，实现桌面↔笔记本 `ssh` 免密登录；步骤与本仓库无关，
按需配置即可。