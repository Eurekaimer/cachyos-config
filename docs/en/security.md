# Security and publishing boundaries

[简体中文](../zh-CN/security.md)

This is a public recovery snapshot, not a secrets backup. The capture excludes passwords, SSH/GPG keys, cloud credentials, browser profiles, cookies, Clash profiles and subscriptions, NetworkManager connections, logs, caches, and `.omp` runtime state.

Before publishing any refresh:

```bash
./scripts/audit.sh
```

The audit checks shell syntax, forbidden private/runtime paths, secret-shaped text, symlinks escaping the repository, and GitHub's file-size limit. A passing heuristic audit is necessary but not sufficient: inspect changed files in `configs/`, `packages/`, and `state/` for hostnames, personal paths, filenames, or credentials that do not match a known pattern.

Store excluded credentials in a password manager or encrypted backup. Never weaken the audit or expand a manifest merely to make capture warnings disappear.
