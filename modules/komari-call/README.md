# komari-call：终端聊天助手

来源：[Eurekaimer/KOMABELIKA](https://github.com/Eurekaimer/KOMABELIKA)。

住在终端里的小鞠知花风格聊天程序，通过 cargo 从源码构建安装。需要 Rust
工具链（CachyOS：`sudo pacman -S rust` 或 rustup）。

## 安装

```bash
./scripts/install-komari-call.sh
```

安装后 `komari-call` 同时出现在 `~/.cargo/bin/`（cargo 安装位置）和
`~/.local/bin/`（符号链接，供 PATH 使用）。

## 卸载

```bash
modules/komari-call/uninstall.sh
```
