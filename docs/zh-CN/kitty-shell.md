# Kitty、Shell 与命令行工具

[English](../en/kitty-shell.md)

Kitty 是主要终端。`configs/home/.config/kitty/kitty.conf` 保存行为与字体设置，`themes/shorin.conf` 保存当前配色；Starship 位于 `configs/home/.config/starship.toml`。

仓库采集 `.zshrc`、`.bashrc`、`.bash_profile` 和 `.bash_logout`。`state/system-info.txt` 记录的当前登录 Shell 是 zsh，启动文件已包含在用户快照中。Git 配置保存为 `.gitconfig`，公开快照中的 `user.email` 会由 `capture.sh` 删除。

Fastfetch 和 Micro 配置也属于用户快照。Bun 全局软件包与 Rustup 工具链以清单形式记录，不复制其运行时目录。
