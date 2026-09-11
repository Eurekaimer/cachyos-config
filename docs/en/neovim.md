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
   framework; native `gc` replaces a comment plugin; the theme is a single
   Kanagawa Wave setup in `lua/plugins/theme.lua`.
4. **Lazy-load optional tools.** VimBeGood loads only when its command is run.
5. **Pin the result.** `lazy-lock.json` records plugin revisions for repeatable
   restores.

The resulting lockfile contains **17 plugin repositories**, including the plugin
manager itself.

## Configuration layout

| Path | Responsibility |
| --- | --- |
| `init.lua` | Sets leader keys and loads core modules in deterministic order |
| `lazy-lock.json` | Pins plugin revisions |
| `lua/config/autocmds.lua` | General lifecycle hooks and fcitx5 state handling |
| `lua/config/keymaps.lua` | Global mappings and native completion-menu controls |
| `lua/config/lazy.lua` | Bootstraps lazy.nvim and imports plugin specifications |
| `lua/config/options.lua` | Editor options, toolchain paths, clipboard detection, and theme fallback |
| `lua/plugins/theme.lua` | Kanagawa Wave colorscheme |
| `lua/plugins/ui.lua` | Snacks, the Aerial outline, which-key, and cursor animation |
| `lua/plugins/editing.lua` | Surround editing, autosave, snippet engine, and motion practice |
| `lua/plugins/syntax.lua` | Treesitter parsers and highlighting |
| `lua/plugins/markdown.lua` | In-editor Markdown rendering and inline images |
| `lua/plugins/java.lua` | nvim-jdtls: the Java language server and JDT extension commands |
| `lua/plugins/lsp.lua` | Mason, LSP servers, native completion, diagnostics, and code navigation |
| `lua/snippets/markdown.lua` | Markdown-only TeX formula snippets |

Configuration comments are concise English sentences. User-facing
key descriptions remain Chinese so which-key is useful during normal editing.

## Retained plugins

The table is alphabetized by project name. Every project has a narrow ownership
boundary; the reason column is the acceptance test for keeping it.

| Project | Load behavior | Purpose | Why it is retained |
| --- | --- | --- | --- |
| [aerial.nvim](https://github.com/stevearc/aerial.nvim) | `AerialToggle` and the other Aerial commands | Multi-level heading/code outline, jump navigation, and Markdown body folding | Long Markdown documents need a structural view that also drives folding; one plugin covers browsing and folding, and other filetypes keep their own fold settings. |
| [auto-save.nvim](https://github.com/okuuva/auto-save.nvim) | `InsertLeave`, `TextChanged` | Writes the buffer to disk after leaving Insert mode or on text changes | Guards writing work against a power loss or a killed window; manual saving still works and no extra mapping is added. |
| [image.nvim](https://github.com/3rd/image.nvim) | Kitty + `markdown` only | Renders Markdown inline images and image files inside the editor | Core Neovim cannot draw images. It activates only in terminals that speak the Kitty graphics protocol and is skipped elsewhere. |
| [kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) | Startup | Provides the Kanagawa Wave colorscheme | Long reading and writing sessions need a low-contrast palette; `options.lua` still keeps a built-in fallback. |
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Startup | Plugin installation, dependency resolution, lazy-loading, lockfile management | A small manager is required to reproduce the plugin set. It also removes the need for custom clone/update scripts. |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | `markdown` only | Expands TeX formula snippets in Markdown | Formula snippets need a maintainable snippet engine; it loads only for markdown files and costs nothing elsewhere. |
| [mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) | Startup | Maps nvim-lspconfig server names to Mason packages | Keeps the seven-server install list declarative and avoids duplicating package-name mappings. |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | Startup | Installs language-server binaries under Neovim's data directory | Language servers otherwise require seven separate system/package-manager workflows. Mason is kept only for developer tools, not general plugins. |
| [mini.surround](https://github.com/nvim-mini/mini.surround) | Startup | Adds, deletes, finds, highlights, and replaces surrounding pairs | Core Neovim has no equivalent operator for changing quotes/brackets around text. This removes many repeated delete-and-insert edits. |
| [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls) | `java` filetype | JDT extensions for eclipse.jdt.ls: organize imports, extract variable/constant/method, and compile/restart commands | A bare LSP client only completes and navigates; `vim.lsp.enable("jdtls")` cannot reach these Java-specific operations, and Java is the primary language being written right now. |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Startup | Supplies maintained defaults for common language servers | Neovim owns the LSP client, but server-specific commands, filetypes, and root markers still need reliable defaults. |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Startup | Downloads parser sources and queries for Neovim's native Treesitter runtime | Neovim provides the highlighter, but not all language parsers and queries. One plugin covers every configured language. |
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | `markdown` only | Renders headings, lists, tables, and code blocks inside the editor | Writing no longer needs a preview window; `Space mr` toggles rendering off to read the source. |
| [smear-cursor.nvim](https://github.com/sphamba/smear-cursor.nvim) | `VeryLazy` | Simulates Neovide's cursor-trail animation in the terminal | The same configuration feels consistent in the terminal and in Neovide; it disables itself inside Neovide at no cost. |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | Startup, modules on demand | Dashboard, explorer, fuzzy picker, notifications, big-file handling, status column, Zen mode, buffer deletion, and LazyGit terminal | This single repository replaces several conventional UI plugins and is the main reason the plugin stack stays small. |
| [vim-be-good](https://github.com/ThePrimeagen/vim-be-good) | Only on `:VimBeGood` | Interactive motion practice | It directly supports learning Vim motions, never loads during normal editing, and can be removed after the training period. |
| [vim-clang-format](https://github.com/rhysd/vim-clang-format) | C-family and Java filetypes | Formats code by driving the system `clang-format` binary | Neovim ships no C-family formatter; driving the official binary reuses each project's existing `.clang-format` instead of maintaining a second style definition. |
| [vim-repeat](https://github.com/tpope/vim-repeat) | LuaSnip dependency | Makes snippet expansion work with `.` repeat | LuaSnip's companion dependency; without it repeated expansions lose their semantics. |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | `VeryLazy` | Shows available continuations after leader/prefix keys | While the user is still learning modal editing, discoverability is worth more than one tiny plugin; revisit it once the mappings become muscle memory. |

## Omitted plugins

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
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | Omitted. The Kanagawa Wave setup in `lua/plugins/theme.lua` owns the palette; a second theme plugin is unnecessary. |

## External requirements

The first column is alphabetized. Required extras are recorded in
`packages/required-extra.txt`; explicit workstation packages remain in
`packages/pacman-explicit.txt`.

| Requirement | Status | Used by |
| --- | --- | --- |
| `clang-format` (`clang` package) | Explicit package | `Space cF` formatting for C/C++/Java and other C-family files |
| `fd` | Required extra | Fast file discovery in Snacks picker |
| `jdk-openjdk` / `jdk21-openjdk` | Explicit packages | eclipse.jdt.ls needs a Java 21+ runtime |
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

Snacks is the only general UI layer.

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

## File tree and code outline

File browsing and previews remain Snacks responsibilities: `Space e` toggles the
file tree, `Space Space` or `Space ff` opens the picker with its preview pane,
and `Space mr` / `Space mi` control Markdown rendering and inline images. These
are the two everyday entry points—`Space e` for the directory tree, `Space a`
for the structure of the current file.

Headings and code structure are handled by Aerial. In Normal mode, `Space a`
(space, then `a`) opens the outline on the right and focuses it; pressing it
again closes the outline. Markdown opens fully expanded, and collapsing an
outline node also folds the matching section body, subheadings included, without
deleting text. Other filetypes still list their code symbols, but section
folding is not taken over.

These mappings only apply inside the outline window:

| Mapping | Action |
| --- | --- |
| `j` / `k` | Select the next/previous visible heading across levels |
| `<Enter>` | Jump to the selected heading and return to the body |
| `p` | Scroll the body to the selected heading, keeping focus in the outline |
| `h` / `l` | Collapse/expand the current node |
| `zC` / `zO` | Recursively collapse/expand the current node and all children |
| `za` / `zA` | Toggle the current node / toggle recursively |
| `zM` / `zR` | Collapse/expand the whole outline |
| `q` | Close the outline |
| `?` | Show the outline mappings |

The global `Ctrl-h/j/k/l` window switches, `Ctrl-s` save, and `L` end-of-line
mapping are preserved. The outline window is read-only, so return to the body
with `Ctrl-h` before saving. The upstream `{` / `}` heading jumps are not
adopted, to avoid overriding the original paragraph motions.

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

Buffers are also written automatically after leaving Insert mode and on text
changes (`auto-save.nvim`); a power loss or a killed window costs at most one
debounce window of edits, and manual saving still works.

Run `:VimBeGood` for motion practice. Because the plugin is command-loaded, it
has no normal startup cost.

## LSP and native completion

Configured servers are alphabetized by language:

| Language | nvim-lspconfig name | Mason package |
| --- | --- | --- |
| Bash | `bashls` | `bash-language-server` |
| Go | `gopls` | `gopls` |
| Java | `jdtls` (started by nvim-jdtls) | `jdtls` |
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

### Java

Java runs on eclipse.jdt.ls, started by `nvim-jdtls`. `lsp.lua` only asks Mason
to install the `jdtls` launcher; it deliberately does not call
`vim.lsp.enable("jdtls")`, which would attach a second client. The project root
is found by walking upward through `gradlew`, `mvnw`, `settings.gradle{,.kts}`,
`pom.xml`, `build.gradle{,.kts}`, and finally `.git`; the index is cached under
`~/.cache/nvim/jdtls/<project>`.

In addition to the mappings listed above, `.java` buffers get:

| Mapping | Action |
| --- | --- |
| `Space co` | Organize imports |
| `Space cv` | Extract variable (visual mode: the selected expression) |
| `Space cc` | Extract constant (same) |
| `Space cm` | Extract method (visual mode only) |

`eclipse.jdt.ls` also advertises `textDocument/formatting`, so `Space cf` works
in Java as well. The commands `:JdtCompile`, `:JdtRestart`, `:JdtBytecode`,
and `:JdtUpdateConfig` are available too.

### Formatting with clang-format

`vim-clang-format` drives the system `clang-format` binary (shipped by the
`clang` package) for `c`, `cpp`, `objc`, `java`, `javascript`, `typescript`,
`proto`, `cuda`, and `vala`. In those filetypes `Space cF` formats the whole
file, or only the selected range in visual mode.

Style resolution order:

1. Walk upward from the file's directory looking for `.clang-format` or
   `_clang-format`; when one is found, pass `-style=file`.
2. Otherwise fall back to `{BasedOnStyle: google, IndentWidth: <shiftwidth>}`.

`Space cf` (LSP formatting) and `Space cF` (clang-format) are independent
paths: the former runs inside the language server, the latter always invokes
the external binary.

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
Mason downloads, parser binaries, caches, and undo history are not
committed; the configuration and lockfile reproduce them.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Completion does not appear | Run `:checkhealth vim.lsp`, then `:LspInfo`; verify a server is attached and use `Ctrl-Space`. |
| File or text search is empty | Verify `fd` and `rg` are on `PATH`; run `:checkhealth snacks`. |
| LSP installation fails for Bash/Python/TypeScript | Verify `npm --version`, then retry from `:Mason`. |
| Parser compilation fails | Verify `tree-sitter --version` and a C compiler are available, then run `:TSUpdate`. |
| Java does not respond, or reports `Java XY language features are not available` | Verify a JDK 21+ is on `PATH`, then run `:JdtRestart`; the index lives under `~/.cache/nvim/jdtls/` and can be deleted to rebuild it. |
| `Space cF` reports that clang-format is missing | Install `clang` and confirm `clang-format --version` runs. |
| Plugin startup fails | Open `:Lazy`, inspect the failed task, then run sync again. |
| System clipboard is unavailable | Install `wl-clipboard`; the config enables `unnamedplus` only when a provider exists. |
