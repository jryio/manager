# SSH keys + config inventory
- source: ls -la ~/.ssh; ssh-keygen -l (fingerprints only); ~/.ssh/config
- captured-at: 2026-05-18
- machine: AVA (macOS 15.5)
- captured-by: inventory-ssh agent
- SAFETY: this artifact contains fingerprints, key types, comments, and Host blocks ONLY. No private key bytes. No public key bytes either (fingerprint is the canonical identifier).

## ~/.ssh/ directory listing

```
drwx------@  CASE staff      .                                  (dir)
-rw-r--r--@  CASE staff 6148 .DS_Store                          mtime 2025-10-27
lrwxr-xr-x@  CASE staff   74 1password-agent.sock ->            mtime 2025-12-10
                              /Users/CASE/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
-rw-------@  CASE staff  297 allowed_signers                    mtime 2026-02-07
-rw-------   CASE staff    0 authorized_keys                    mtime 2016-04-01  (empty)
-rw-------   CASE staff 3243 calhacks_aws                       mtime 2016-11-04
-rw-r--r--   CASE staff  738 calhacks_aws.pub                   mtime 2016-11-04
-rw-r--r--@  CASE staff  320 config                             mtime 2025-12-10
-rw-------   CASE staff 1766 gitlab                             mtime 2016-04-01
-rw-r--r--   CASE staff  394 gitlab.pub                         mtime 2016-04-01
-rw-------@  CASE staff 1702 gradebot_rsa                       mtime 2017-09-30  (no .pub on disk)
-rw-------   CASE staff 3326 id_rsa                             mtime 2015-12-23
-rw-r--r--@  CASE staff  738 id_rsa.pub                         mtime 2015-12-23
-rw-------@  CASE staff   80 infinite-music.pub                 mtime 2025-12-01  (orphan public, no private on disk)
-rw-------   CASE staff   80 jry_archive_intel.pub              mtime 2025-10-27  (orphan public, no private on disk)
-r--------@  CASE staff 1704 jry-aws-temp.pem                   mtime 2021-02-10  (no .pub on disk)
-r--------@  CASE staff 1696 jry.pem                            mtime 2017-09-27  (no .pub on disk)
-rw-r--r--   CASE staff  128 rc                                 mtime 2018-10-17
lrwxr-xr-x   CASE staff   51 ssh_auth_sock ->                   mtime 2018-10-17  (stale launchd socket; pre-1Password)
                              /private/tmp/com.apple.launchd.ZDzidRgwV5/Listeners
-rw-------@  CASE staff   80 tdna.pub                           mtime 2025-01-17  (orphan public, no private on disk)
-rw-r--r--@  CASE staff   80 zigguratum.pub                     mtime 2024-09-02  (orphan public, no private on disk)
```

(`known_hosts` and `known_hosts.old` excluded from listing per task constraints — present, ~412–423 KB each, both touched 2026-01-25.)

## Per-key disposition table

| File                  | Type    | Bits | Fingerprint (SHA256)                                         | Comment       | mtime      | atime      | Last used (best guess)                  | Recommended action |
|-----------------------|---------|-----:|--------------------------------------------------------------|---------------|------------|------------|------------------------------------------|--------------------|
| id_rsa                | RSA     | 4096 | SHA256:+ZrV9nQ8hSEVsq+3bmIuND+anUBfAZMwA3bA7v5ULc4           | jacob@jry.io  | 2015-12-23 | 2015-12-23 | private file never re-read since 2015    | RETIRE             |
| id_rsa.pub            | RSA     | 4096 | SHA256:+ZrV9nQ8hSEVsq+3bmIuND+anUBfAZMwA3bA7v5ULc4           | jacob@jry.io  | 2015-12-23 | 2025-10-27 | pub read 2025-10-27 (likely ssh-add scan)| RETIRE             |
| gitlab                | RSA     | 2048 | SHA256:y5KVZ9c2sVOtard73Pqpaam01le9p7/vMpoZS292zzA           | jacob@jry.io  | 2016-04-01 | 2025-10-27 | private read 2025-10-27 (likely scan)    | RETIRE             |
| gitlab.pub            | RSA     | 2048 | SHA256:y5KVZ9c2sVOtard73Pqpaam01le9p7/vMpoZS292zzA           | jacob@jry.io  | 2016-04-01 | 2016-04-01 | never re-read                            | RETIRE             |
| calhacks_aws          | RSA     | 4096 | SHA256:mJYmVl5lJcDRTp0eJl4SJXH550qRzQ67annejuSWewY           | jacob@jry.io  | 2016-11-04 | 2016-11-04 | never re-read                            | RETIRE             |
| calhacks_aws.pub      | RSA     | 4096 | SHA256:mJYmVl5lJcDRTp0eJl4SJXH550qRzQ67annejuSWewY           | jacob@jry.io  | 2016-11-04 | 2016-11-04 | never re-read                            | RETIRE             |
| gradebot_rsa          | RSA     | 2048 | SHA256:HUAK+sxydv8GTz5K8CmpTQAiJL4eXXxo8zJYFEiWkdI           | (none)        | 2017-09-30 | 2017-09-30 | never re-read                            | RETIRE             |
| jry.pem               | RSA     | 2048 | SHA256:icUImY+uWZADoh1as2W1bGGn7f4GlB16AcEwZqy3dL4           | (none)        | 2017-09-27 | 2025-10-27 | read 2025-10-27 (likely scan)            | UNKNOWN            |
| jry-aws-temp.pem      | RSA     | 2048 | SHA256:mCE7DOzHecDNQjg772N9XjsWHdTsNhAWnJYN5seSk54           | (none)        | 2021-02-10 | 2025-10-27 | read 2025-10-27 (likely scan); 4y old    | UNKNOWN            |
| infinite-music.pub    | ED25519 |  256 | SHA256:rircqQQBuiC9lmn2PMn/h/RGX8P59cXnscK1d8FdA3k           | (none)        | 2025-12-01 | 2025-12-01 | pub created 2025-12-01; private in vault | VAULT (already)    |
| tdna.pub              | ED25519 |  256 | SHA256:DXfyLK1dbLy3CroikJl44TuOec4JNGjVCzC1mODzb40           | (none)        | 2025-01-17 | 2025-10-27 | pub created 2025-01-17; private in vault | VAULT (already)    |
| zigguratum.pub        | ED25519 |  256 | SHA256:oV+hEMfj2J7yrso7q8RutNJr1jTXyhss/xXL3XsaQQs           | (none)        | 2024-09-02 | 2024-09-02 | pub created 2024-09-02; private in vault | VAULT (already)    |
| jry_archive_intel.pub | ED25519 |  256 | SHA256:Zg3RNiHIwQq9uqRw7Izu0D+7KeU9NhVYodfXg1zW1G8           | (none)        | 2025-10-27 | 2025-10-27 | pub created 2025-10-27; private in vault | VAULT (already)    |
| authorized_keys       | (empty) |    — | —                                                            | —             | 2016-04-01 | 2016-04-01 | zero-byte file from 2016                 | RETIRE             |

### Disposition notes

- **Orphan public keys** (`infinite-music.pub`, `tdna.pub`, `zigguratum.pub`, `jry_archive_intel.pub`): no matching private key on disk. Per D18 the private halves are already in 1Password; only the `.pub` is published here. These are the four current identities. The pub files themselves can stay on disk if a workflow needs them, but the canonical home is the vault — they are also enumerated in `allowed_signers` for git commit signature verification.
- **Stale RSA pairs** (`id_rsa`, `gitlab`, `calhacks_aws`, `gradebot_rsa`): every private file's atime equals its mtime, meaning OpenSSH/agent never opened them after creation. mtimes range 2015–2017. Not referenced by `~/.ssh/config`. None are 1Password-vault candidates — they are dead.
- **AWS PEMs** (`jry.pem`, `jry-aws-temp.pem`): no Host block references them; the `-temp` suffix on the 2021 file signals it was throwaway four years ago. Both pubs were read on 2025-10-27 (single batch scan day, see `id_rsa.pub`/`gitlab` atimes). Recommend confirming with user whether either AWS instance still exists before retiring; until then UNKNOWN.
- **`authorized_keys`**: zero-byte file from 2016. This host accepts no inbound SSH (no service uses it). RETIRE.
- **`ssh_auth_sock`** symlink: points at `/private/tmp/com.apple.launchd.ZDzidRgwV5/Listeners`, a 2018-vintage launchd socket path. Predates the 1Password agent migration. Dead symlink — RETIRE alongside the key cleanup.
- **`rc`** (2018, 128 B): standard-named SSH per-connection startup file. Not in scope of the key inventory but flagging for the next session: contents should be audited before keeping.

### Summary counts
- VAULT (already in vault, pub stays on disk for signing/reference): **4** (infinite-music, tdna, zigguratum, jry_archive_intel)
- RETIRE (delete during migration): **5 key files / 4 pairs + 1 empty `authorized_keys`** (id_rsa pair, gitlab pair, calhacks_aws pair, gradebot_rsa private, authorized_keys)
- UNKNOWN (need user confirmation): **2** (jry.pem, jry-aws-temp.pem)
- VAULT-required new migration: **0** — every still-in-use private key is already in 1Password.

## ~/.ssh/config Host blocks (raw)

```
# Common settings for all hosts
ServerAliveInterval 60

Host *
  ServerAliveInterval 600
  UseKeychain yes
  AddKeysToAgent yes
  IdentitiesOnly yes
  TCPKeepAlive yes
  IPQoS=throughput
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

Host github.com
  User git
  HostName github.com
```

No secrets, no private-key paths, no `IdentityFile` lines. The `Host *` block already points `IdentityAgent` at the 1Password socket (matches D18 intent). No per-host blocks differentiate between the four vault identities — that selection is currently delegated to 1Password's agent. Once `programs.ssh.matchBlocks` is authored in `modules/home-manager/ssh.nix`, per-identity Host blocks should be added (github-jry, github-tdna, github-zigg, github-inf) so the agent surfaces the right key per remote.

## allowed_signers
- present: yes (`~/.ssh/allowed_signers`, mode `-rw-------`)
- size: 297 bytes
- mtime: 2026-02-07 10:06:53
- contents: **not included** (file maps the four ED25519 public keys above to git identities; reserved for the Home Manager ssh.nix / git.nix module work)

## 1Password agent socket
- `~/.ssh/1password-agent.sock` is a symlink (`lrwxr-xr-x`, 74 bytes, mtime 2025-12-10 12:49:24)
- target: `/Users/CASE/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
- target exists and is a live unix-domain socket (`srw-------`, mtime 2026-05-16 20:47) — 1Password agent currently running.

## Safety scan
- No private-key bytes recorded anywhere in this artifact.
- No public-key bytes recorded (fingerprints only, plus the `comment` field returned by `ssh-keygen -l`).
- `~/.ssh/config` contains no literal secrets — no tokens, no `IdentityFile` paths, no `ProxyCommand` with credentials.
- No private key found written into `~/.ssh/config` or any non-key file.
- All private key files retain `-rw-------` or `-r--------` mode; no world/group readability.
- `authorized_keys` is empty — confirms no inbound SSH access is currently authorized for the CASE account.
