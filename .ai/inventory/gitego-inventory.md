# gitego inventory

- captured-at: 2026-05-18
- machine: AVA (macOS 15.5)
- captured-by: inventory-git agent
- feeds: D25 (declarative gitego HM module), D18 (SSH key vault migration), D12 (secrets registry)

## Identities

All 5 expected identities confirmed in `~/.gitego/config.yaml`:

| profile | name        | email                       | ssh_keys (config.yaml)              | profile gitconfig fragment                  | auto_rules paths                                                                                          |
|---------|-------------|-----------------------------|-------------------------------------|---------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| jry     | Jacob Young | git@jry.io                  | `/Users/CASE/.ssh/id_rsa`           | `~/.gitego/profiles/jry.gitconfig`          | `/Users/CASE/code/personal/statis/`, `/Users/CASE/code/personal/jryio/`, `/Users/CASE/code/personal/adr/` |
| inf     | Jacob Young | git@sancho.studio           | `/Users/CASE/.ssh/infinite-music`   | `~/.gitego/profiles/inf.gitconfig`          | `/Users/CASE/code/professional/infinitemusic/`                                                            |
| tdna    | Jacob Young | jacob.young@tech-dna.net    | `/Users/CASE/.ssh/tdna`             | `~/.gitego/profiles/tdna.gitconfig`         | `/Users/CASE/code/professional/tdna/`                                                                     |
| zigg    | Jacob Young | jacob.young@ziggiz.ai       | `/Users/CASE/.ssh/zigguratum`       | `~/.gitego/profiles/zigg.gitconfig`         | `/Users/CASE/code/professional/zigg/`                                                                     |
| keybase | Jacob Young | jacob@keyba.se              | (none)                              | `~/.gitego/profiles/keybase.gitconfig`      | `/Users/CASE/code/professional/keybase/`                                                                  |

`active_profile: jry` is set in `config.yaml`.

Total auto_rules entries: **7** (3 for `jry`, 1 each for `inf`/`tdna`/`zigg`/`keybase`).

## Drift check: config.yaml profile references vs. on-disk `~/.gitego/profiles/*.gitconfig`

All 5 profile fragments listed in `config.yaml` exist on disk:

| profile      | on-disk fragment                            | status  |
|--------------|---------------------------------------------|---------|
| inf          | `~/.gitego/profiles/inf.gitconfig`          | PRESENT |
| jry          | `~/.gitego/profiles/jry.gitconfig`          | PRESENT |
| keybase      | `~/.gitego/profiles/keybase.gitconfig`      | PRESENT |
| tdna         | `~/.gitego/profiles/tdna.gitconfig`         | PRESENT |
| zigg         | `~/.gitego/profiles/zigg.gitconfig`         | PRESENT |

No orphan fragments. No missing fragments. Zero drift between `config.yaml` and on-disk profile fragments.

### Profile fragment contents (verbatim, for D25 reproduction)

`jry.gitconfig` — bare identity, no signing, plain `ssh -i ~/.ssh/id_rsa`:

```ini
[user]
    name = Jacob Young
    email = git@jry.io

[core]
    sshCommand = ssh -i /Users/CASE/.ssh/id_rsa
```

`inf.gitconfig`, `tdna.gitconfig`, `zigg.gitconfig` — all follow the same shape: SSH-signed commits via 1Password `op-ssh-sign`, `IdentityAgent` pointed at the 1Password socket, `IdentityFile` set to the `.pub` half on disk. Each has a different `signingkey` (the `.pub` blob inline) and a different `IdentityFile`:

- `inf`: signingkey `ssh-ed25519 …OWQQtfQV4Di7pJFuK6A7ldAPCuoqvPhX0Glgt3M/9RR`, IdentityFile `~/.ssh/infinite-music.pub`
- `tdna`: signingkey `ssh-ed25519 …LIcLG93apm3T5H5lr2EVnUb9fxwHGC/UZd+N4rSVmCg`, IdentityFile `~/.ssh/tdna.pub`
- `zigg`: signingkey `ssh-ed25519 …EnINOEEW6WoY3Fmbb/gwMDThV+bKjaB9TK0kO0WybT8`, IdentityFile `~/.ssh/zigguratum.pub`

Common across `inf`/`tdna`/`zigg`:

```ini
[commit]
    gpgsign = true
[gpg]
    format = ssh
[gpg "ssh"]
    program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    allowedSignersFile = ~/.ssh/allowed_signers
[core]
    sshCommand = ssh -o IdentityAgent=/Users/CASE/.ssh/1password-agent.sock -o IdentitiesOnly=yes -o IdentityFile=…
```

`keybase.gitconfig` — bare `[user]` block, no SSH key, no signing config:

```ini
[user]
    name = Jacob Young
    email = jacob@keyba.se
```

## Global `~/.gitconfig` gitego-generated blocks

The global `~/.gitconfig` carries **6** `includeIf "gitdir:…"` blocks that gitego owns:

```ini
[includeIf "gitdir:/Users/CASE/code/professional/infinitemusic/"]
    path = /Users/CASE/.gitego/profiles/inf.gitconfig
[includeIf "gitdir:/Users/CASE/code/professional/tdna/"]
    path = /Users/CASE/.gitego/profiles/tdna.gitconfig
[includeIf "gitdir:/Users/CASE/code/professional/zigg/"]
    path = /Users/CASE/.gitego/profiles/zigg.gitconfig
[includeIf "gitdir:/Users/CASE/code/professional/keybase/"]
    path = /Users/CASE/.gitego/profiles/keybase.gitconfig
[includeIf "gitdir:/Users/CASE/code/professional/tdna/genome/"]
    path = /Users/CASE/.gitego/profiles/tdna.gitconfig
[includeIf "gitdir:/Users/CASE/code/personal/statis/"]
    path = /Users/CASE/.gitego/profiles/jry.gitconfig
```

### Drift check: `config.yaml` auto_rules vs. global `includeIf` blocks

| auto_rule path                                       | profile | matching `includeIf` in `~/.gitconfig`? |
|------------------------------------------------------|---------|-----------------------------------------|
| `/Users/CASE/code/professional/infinitemusic/`       | inf     | yes                                     |
| `/Users/CASE/code/professional/tdna/`                | tdna    | yes                                     |
| `/Users/CASE/code/professional/zigg/`                | zigg    | yes                                     |
| `/Users/CASE/code/professional/keybase/`             | keybase | yes                                     |
| `/Users/CASE/code/personal/statis/`                  | jry     | yes                                     |
| `/Users/CASE/code/personal/jryio/`                   | jry     | **MISSING** in `~/.gitconfig`           |
| `/Users/CASE/code/personal/adr/`                     | jry     | **MISSING** in `~/.gitconfig`           |

`~/.gitconfig` also has one **extra** `includeIf` not represented in `config.yaml`:

- `gitdir:/Users/CASE/code/professional/tdna/genome/` → `tdna.gitconfig` (presumed manual edit; `tdna/genome/` is a subtree of `tdna/` so it is redundant but harmless).

D25 implementation should regenerate `includeIf` blocks from `config.yaml.auto_rules` as the single source of truth; this will drop the redundant `tdna/genome/` rule and add `jryio/` + `adr/`. Confirm with operator whether `jryio/`/`adr/` were ever in scope or if `gitego` was simply never re-run after editing `config.yaml`.

## Global git config — gitego-relevant keys

```
gpg.program=gpg
commit.gpgsign=true
credential.helper=!gitego credential
user.name=Jacob Young
user.email=git@jry.io
user.signingkey=715CED2327899E28
```

Notes for D25/D18 module work:

- `credential.helper=!gitego credential` — gitego acts as a credential helper shim. Must be preserved in the HM module.
- `user.signingkey=715CED2327899E28` is a **GPG long-key ID**, not an SSH key. The global default identity still signs with GPG, but every per-profile fragment (`inf`/`tdna`/`zigg`) overrides to SSH-signing via `op-ssh-sign`. Per D29 (SSH-signing-only world), the global `signingkey` plus `gpg.program=gpg` likely become stale once `jry` adopts SSH signing too. Flag for D25 review.
- `[url "git@zigg:zigguratum-core"]` and `[url "git@tdna:tech-dna"]` host-alias rewrites also live in `~/.gitconfig`; not gitego-owned but Topic 04 (git) will need to regenerate them.

## D18 cross-reference: ssh_keys path → on-disk private-key status

| profile | ssh_keys path                       | on-disk private key | notes                                                                                            |
|---------|-------------------------------------|---------------------|--------------------------------------------------------------------------------------------------|
| jry     | `/Users/CASE/.ssh/id_rsa`           | **PRESENT**         | Only private key still on disk; D18 says migrate into 1Password vault.                           |
| inf     | `/Users/CASE/.ssh/infinite-music`   | **MISSING**         | Only `.pub` remains (`~/.ssh/infinite-music.pub`); private half already lives in 1Password.      |
| tdna    | `/Users/CASE/.ssh/tdna`             | **MISSING**         | Only `.pub` remains (`~/.ssh/tdna.pub`); private half already lives in 1Password.                |
| zigg    | `/Users/CASE/.ssh/zigguratum`       | **MISSING**         | Only `.pub` remains (`~/.ssh/zigguratum.pub`); private half already lives in 1Password.          |
| keybase | (no `ssh_key` in `config.yaml`)     | n/a                 | keybase profile is HTTPS-only; nothing to migrate.                                               |

Implication for D25: the `config.yaml` schema still references `ssh_key:` paths that **no longer resolve to a usable private key** for `inf`/`tdna`/`zigg`. In practice, the per-profile `core.sshCommand` already routes through `IdentityAgent=/Users/CASE/.ssh/1password-agent.sock` + `IdentityFile=…/<name>.pub`, so authentication still works via the 1Password agent. The `ssh_key:` path in `config.yaml` appears to be informational (or used only by `gitego` CLI for legacy commands like `ssh -i`), not load-bearing for daily auth.

D18 action: migrate `~/.ssh/id_rsa` into the 1Password vault, then `jry.gitconfig` will need the same `IdentityAgent`/`IdentityFile`/`op-ssh-sign` shape as the other profiles. After migration, **no** private SSH keys remain in `~/.ssh/` — only `*.pub` files and `allowed_signers`.

## Secrets check

`~/.gitego/config.yaml` contains **no literal secrets** (no tokens, no passwords). The only credential-adjacent value is `credential.helper=!gitego credential` in `~/.gitconfig`, which invokes the gitego binary at runtime to delegate to whatever credential helper the active profile defines. No redaction required. No `op://…` placeholders needed for the gitego config surface specifically — but downstream credential helpers may still need them (defer to D12 secrets registry).
