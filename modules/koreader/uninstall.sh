#!/usr/bin/env bash
set -Eeuo pipefail

module_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# Uninstall reverses only the system-side half of the module: the two patched
# Lua files under /usr/lib/koreader are restored to their upstream originals
# (a koreader-bin upgrade replaces them anyway). The user's ~/.config/koreader
# keyboard configuration is deliberately kept: it is restored from the generic
# snapshot (configs/apps/koreader) and removing it would destroy device
# bindings the user still wants.
exec "$module_dir/install.sh" --restore "$@"
