# Neovim

[简体中文](../zh-CN/neovim.md)

This workstation uses a small, LazyVim-inspired Neovim configuration without
importing the full LazyVim distribution. The goal is to retain the parts that
change daily editing—search, navigation, LSP, Treesitter, and discoverable
keymaps—while preferring Neovim 0.12 built-ins whenever they can replace a
plugin.

## Design rules

1. **One plugin must solve more than one recurring problem, or solve one problem
   that Neovim cannot solve well on its own.**
2. **No overlapping plugins.** Snacks is the only picker, explorer, dashboard,
   notification, and floating-terminal layer.
3. **Use Neovim 0.12 first.** Native LSP completion replaces a completion
   framework; native `gc` replaces a comment plugin; `habamax` replaces a theme
   plugin.
4. **Lazy-load optional tools.** VimBeGood loads only when its command is run.
5. **Pin the result.** `lazy-lock.json` records plugin revisions for repeatable
   restores.

The resulting lockfile contains **9 plugin repositories**, including the plugin
manager itself.

## Configuration layout

| Path | Responsibility |
| --- | --- |
| `init.lua` | Sets leader keys and loads core modules in deterministic order |
| `lazy-lock.json` | Pins plugin revisions |
| `lua/config/autocmds.lua` | General lifecycle hooks and fcitx5 state handling |
| `lua/config/keymaps.lua` | Global mappings and native completion-menu controls |
| `lua/config/lazy.lua` | Bootstraps lazy.nvim and imports plugin specifications |
| `lua/config/options.lua` | Editor options, toolchain paths, clipboard detection, and bundled colorscheme |
| `lua/plugins/editor.lua` | Treesitter, surround editing, and movement training |
| `lua/plugins/lsp.lua` | Mason, LSP servers, native completion, diagnostics, and code navigation |
| `lua/plugins/ui.lua` | Snacks and which-key |

Configuration comments are intentionally concise English sentences. User-facing
key descriptions remain Chinese so which-key is useful during normal editing.

## Retained plugins

The table is alphabetized by project name. Every project has a narrow ownership
boundary; the reason column is the acceptance test for keeping it.

| Project | Load behavior | Purpose | Why it is retained |
| --- | --- | --- | --- |
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Startup | Plugin installation, dependency resolution, lazy-loading, lockfile management | A small manager is required to reproduce the plugin set. It also removes the need for custom clone/update scripts. |
| [mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) | Startup | Maps nvim-lspconfig server names to Mason packages | Keeps the six-server install list declarative and avoids duplicating package-name mappings. |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | Startup | Installs language-server binaries under Neovim's data directory | Language servers otherwise require six separate system/package-manager workflows. Mason is kept only for developer tools, not general plugins. |
| [mini.surround](https://github.com/nvim-mini/mini.surround) | Startup | Adds, deletes, finds, highlights, and replaces surrounding pairs | Core Neovim has no equivalent operator for changing quotes/brackets around text. This removes many repeated delete-and-insert edits. |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Startup | Supplies maintained defaults for common language servers | Neovim owns the LSP client, but server-specific commands, filetypes, and root markers still need reliable defaults. |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Startup | Downloads parser sources and queries for Neovim's native Treesitter runtime | Neovim provides the highlighter, but not all language parsers and queries. One plugin covers every configured language. |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | Startup, modules on demand | Dashboard, explorer, fuzzy picker, notifications, big-file handling, status column, Zen mode, buffer deletion, and LazyGit terminal | This single repository replaces several conventional UI plugins and is the main reason the plugin stack stays small. |
| [vim-be-good](https://github.com/ThePrimeagen/vim-be-good) | Only on `:VimBeGood` | Interactive motion practice | It directly supports learning Vim motions, never loads during normal editing, and can be removed after the training period. |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | `VeryLazy` | Shows available continuations after leader/prefix keys | While the user is still learning modal editing, discoverability is worth more than one tiny plugin; it can be reconsidered once the mappings become muscle memory. |

## Deliberately omitted plugins

These are not missing features. They are cases where Neovim or an already
retained plugin owns the same responsibility.

| Candidate | Decision and replacement |
| --- | --- |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Omitted. `Space gg` opens LazyGit through Snacks; adding a second Git presentation layer was not essential. |
| [lazydev.nvim](https://github.com/folke/lazydev.nvim) | Omitted. `lua_ls` receives `VIMRUNTIME` as its workspace library, which is enough for this small config. |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Omitted. The native statusline plus Snacks status column carries the necessary file/mode/diagnostic context. |
| [mini.comment](https://github.com/nvim-mini/mini.comment) | Omitted. Neovim 0.12 already provides `gc` and `gcc`. |
| [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) | Omitted. Snacks explorer owns file browsing. |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) and its source/snippet extensions | Omitted. `vim.lsp.completion` provides LSP completion, reducing six repositories to zero. Native `Ctrl-X Ctrl-F` remains available for path completion. |
| [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | Omitted. Snacks explorer owns file browsing. |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Omitted. Snacks picker owns file, grep, buffer, help, diagnostic, keymap, and LSP searches. |
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | Omitted. Neovim's bundled `habamax` colorscheme is sufficient and requires no download or lock entry. |

## External requirements

The first column is alphabetized. Required extras are recorded in
`packages/required-extra.txt`; explicit workstation packages remain in
`packages/pacman-explicit.txt`.

| Requirement | Status | Used by |
| --- | --- | --- |
| `fd` | Required extra | Fast file discovery in Snacks picker |
| `lazygit` | Explicit package | `Space gg` Git interface |
| `neovim` | Explicit package; current config targets 0.12 | Editor, native LSP completion, native comments, native snippets |
| `npm` | Required extra | Mason packages for Bash, Pyright, and TypeScript language servers |
| `ripgrep` | Explicit package | Project text search in Snacks picker |
| `tree-sitter-cli` | Required extra | Compiles nvim-treesitter v1 parsers |
| `wl-clipboard` | Optional; detected at startup | Wayland system clipboard integration |

## First launch and restore

A normal repository restore installs packages before replacing the user config:

```bash
./scripts/restore-all.sh --dry-run
./scripts/restore-all.sh
```

On the first Neovim launch:

1. `config/lazy.lua` clones lazy.nvim if it is missing.
2. lazy.nvim installs the revisions in `lazy-lock.json`.
3. Mason installs the configured language servers.
4. nvim-treesitter downloads and compiles missing parsers.

Useful status commands:

```vim
:Lazy
:Mason
:checkhealth snacks
:checkhealth vim.lsp
:checkhealth vim.treesitter
```

## Snacks workflow

Snacks is intentionally the only general UI layer.

| Mapping | Action |
| --- | --- |
| `Space Space` | Smart file/buffer search |
| `Space bd` | Delete the current buffer without breaking the window layout |
| `Space e` | Toggle the file explorer |
| `Space fb` | Select an open buffer |
| `Space ff` | Find files from the working directory |
| `Space fg` | Search project text with ripgrep |
| `Space fh` | Search help tags |
| `Space fr` | Open a recent file |
| `Space gg` | Open LazyGit in a floating terminal |
| `Space n` | Show notification history |
| `Space sd` | Search workspace diagnostics |
| `Space sk` | Search all registered keymaps |
| `Space ss` | Search symbols reported by the attached LSP |
| `Space z` | Toggle Zen mode |

`Space sk` is the preferred escape hatch when a mapping is forgotten; it is
faster and more reliable than memorizing this document.

## Editing and window mappings

| Mapping | Action |
| --- | --- |
| `Ctrl-H/J/K/L` | Move between splits |
| `Ctrl-S` or `Space s` | Save |
| `Esc` | Clear search highlighting in Normal mode |
| `J` / `K` in Visual mode | Move the selected lines down/up |
| `jk` in Insert mode | Return to Normal mode |
| `Space bn` / `Space bp` | Next/previous buffer |
| `Space wd` | Close the current split |
| `Space ws` / `Space wv` | Horizontal/vertical split |
| `Space w=` | Equalize split sizes |
| `<` / `>` in Visual mode | Change indentation and preserve the selection |

Native Neovim features retained instead of plugins:

| Mapping | Action |
| --- | --- |
| `gcc` | Toggle a line comment |
| `gc{motion}` | Comment a Vim motion, for example `gcip` for a paragraph |
| `Ctrl-X Ctrl-F` | Complete a filesystem path |
| `u` / `Ctrl-R` | Undo / redo |
| `.` | Repeat the last change |

mini.surround uses its current default mappings:

| Mapping | Action |
| --- | --- |
| `sa{motion}{char}` | Add a surrounding pair |
| `sd{char}` | Delete a surrounding pair |
| `sr{old}{new}` | Replace a surrounding pair |

Run `:VimBeGood` for motion practice. Because the plugin is command-loaded, it
has no normal startup cost.

## LSP and native completion

Configured servers are alphabetized by language:

| Language | nvim-lspconfig name | Mason package |
| --- | --- | --- |
| Bash | `bashls` | `bash-language-server` |
| Go | `gopls` | `gopls` |
| JavaScript / TypeScript | `ts_ls` | `typescript-language-server` |
| Lua | `lua_ls` | `lua-language-server` |
| Python | `pyright` | `pyright` |
| Rust | `rust_analyzer` | `rust-analyzer` |

LSP mappings are buffer-local and appear only after a server attaches:

| Mapping | Action |
| --- | --- |
| `Ctrl-Space` in Insert mode | Request completion |
| `Enter` with menu visible | Accept the selected completion |
| `K` | Show hover documentation |
| `Shift-Tab` / `Tab` with menu visible | Previous/next completion item |
| `Space ca` | Code action |
| `Space cd` | Diagnostic under the cursor |
| `Space cf` | Ask the attached server to format |
| `Space cr` | Rename a symbol |
| `[d` / `]d` | Previous/next diagnostic |
| `gD` / `gd` | Declaration/definition |
| `gI` / `gr` / `gy` | Implementation/references/type definition |

Formatting depends on server capability. For example, Go and Rust servers
format directly; Pyright is primarily a type checker and does not replace a
Python formatter.

## Treesitter

Configured parsers are alphabetized:

`bash`, `go`, `javascript`, `json`, `lua`, `markdown`, `markdown_inline`,
`python`, `query`, `rust`, `toml`, `typescript`, `vim`, `vimdoc`, `yaml`.

Neovim performs highlighting. nvim-treesitter only installs parsers and queries,
then a `FileType` autocmd calls `vim.treesitter.start()` when a parser exists.
This avoids extra Treesitter modules that duplicate core behavior.

## Chinese input method behavior

`lua/config/autocmds.lua` integrates directly with `fcitx5-remote` instead of an
input-method plugin:

1. Leaving Insert mode records whether fcitx5 was active and switches to English.
2. Returning to Insert mode restores the previous active state.
3. Exiting Neovim restores the previous input method.

Normal-mode commands therefore remain ASCII while Chinese Insert-mode input is
preserved.

## Maintenance and synchronization

Edit the live configuration, not the snapshot copy:

```bash
nvim ~/.config/nvim
```

After a successful smoke test:

```bash
cd ~/Documents/GitHub/cachyos-config
./scripts/capture.sh
./scripts/audit.sh

git add -A
git commit -m "feat(nvim): refine minimalist editor config"
git push
```

The nvim directory is allowlisted by `manifests/home-paths.txt`. Plugin data,
Mason downloads, parser binaries, caches, and undo history are intentionally not
committed; the configuration and lockfile reproduce them.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Completion does not appear | Run `:checkhealth vim.lsp`, then `:LspInfo`; verify a server is attached and use `Ctrl-Space`. |
| File or text search is empty | Verify `fd` and `rg` are on `PATH`; run `:checkhealth snacks`. |
| LSP installation fails for Bash/Python/TypeScript | Verify `npm --version`, then retry from `:Mason`. |
| Parser compilation fails | Verify `tree-sitter --version` and a C compiler are available, then run `:TSUpdate`. |
| Plugin startup fails | Open `:Lazy`, inspect the failed task, then run sync again. |
| System clipboard is unavailable | Install `wl-clipboard`; the config enables `unnamedplus` only when a provider exists. |
