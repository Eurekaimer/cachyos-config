# Passwordless Git push (GitHub)

[简体中文](../zh-CN/git-authentication.md)

Publishing a snapshot (`capture.sh` → `git commit` → `git push`) requires
pushing to GitHub without re-entering credentials. Current state: `https` +
GitHub CLI (`gh`) auth with the token in the system keyring; no SSH key
exists yet. Pick either approach below.

## Option A: SSH key (recommended; cleanest across machines)

Independent of keyring and `gh` login state, fits desktop + laptop sync.

```sh
# 1) Generate the key (empty passphrase for truly passwordless push)
ssh-keygen -t ed25519 -C "eurekaimer@github" -f ~/.ssh/id_ed25519

# 2) Add the public key to the GitHub account (either way)
gh ssh-key add ~/.ssh/id_ed25519.pub --title "komari"
#    or open https://github.com/settings/keys → New SSH key and paste

# 3) Switch the remote from https to ssh
git -C ~/Documents/GitHub/cachyos-config remote set-url origin git@github.com:Eurekaimer/cachyos-config.git

# 4) Verify (first run asks about known_hosts; answer yes)
ssh -T git@github.com
#    Success: Hi Eurekaimer! You've successfully authenticated...

# 5) Subsequent git push prompts for nothing
```

## Option B: https + GitHub CLI (current setup)

`gh` supplies git credentials from its keyring token; no per-push prompts.

```sh
gh auth login        # GitHub.com → HTTPS → browser login
gh auth setup-git    # make git use gh as credential helper
gh auth status       # confirm "Logged in" + protocol https
```

Depends on the keyring: a new machine or re-login requires `gh auth login`
again.

## Sharing across machines

- **Generate one key per machine, add all to the same account** (recommended):
  the private key never leaves its host; revoke any single machine when lost.
- **Copy one key to several machines**: copy `~/.ssh/id_ed25519` (and `.pub`)
  into `~/.ssh/` on the other host, then `chmod 600 ~/.ssh/id_ed25519`.
  Updating the key anywhere means re-adding it on GitHub.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `Permission denied (publickey)` | Run `ssh -T git@github.com`; check which account is recognized; key missing/added to the wrong account |
| Multiple keys or a replaced key | Pin `Host github.com` + `IdentityFile ~/.ssh/<key>` in `~/.ssh/config`; `ssh-add -D` to clear stale ssh-agent keys |
| Corrupted `known_hosts` | Remove the github.com line from `~/.ssh/known_hosts` and retry (it re-prompts for trust) |

## Beyond Git: the same key for SSH logins

`~/.ssh/id_ed25519.pub` can also be appended to another machine's
`~/.ssh/authorized_keys` for passwordless `ssh` between desktop and laptop;
that part is independent of this repository.