# Kitty, shells, and command-line tools

[简体中文](../zh-CN/kitty-shell.md)

Kitty is the primary terminal. `configs/home/.config/kitty/kitty.conf` contains behavior and font settings, while `themes/shorin.conf` contains the selected palette. Starship is stored separately at `configs/home/.config/starship.toml`.

Shell startup files are captured from the home directory: `.zshrc`, `.bashrc`, `.bash_profile`, and `.bash_logout`. The current login shell recorded in `state/system-info.txt` is zsh, and its startup files are part of the home snapshot. Git configuration is captured as `.gitconfig`, but `capture.sh` removes `user.email` from the public copy.

Fastfetch and Micro configuration are also part of the user snapshot. Bun global packages and Rustup toolchains are recorded as package manifests rather than copied runtime directories.
