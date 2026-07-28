# GUI-app license inventory (guiAppCasks set)

# source: AVA license artifacts (defaults domains + Application Support files)
# captured-at: 2026-07-28
# NO license keys are recorded here — keys live in 1Password. This maps which
# of the 29 declared GUI casks need activation, how, and where each app stores
# its license so a future activation script (op CLI -> insert) knows its targets.

## License-key apps (paid; script-insertable, keys in 1Password)

| App | Evidence on AVA | License storage (script target) |
|---|---|---|
| Bartender | CONFIRMED (defaults) | `defaults write com.surteesstudios.Bartender license2` + `license2HoldersName` |
| iStat Menus | CONFIRMED (defaults) | `defaults com.bjango.istatmenus` — `license6` (dict), `license5` (string) |
| Hazel | CONFIRMED (file) | `~/Library/Application Support/Hazel/license` |
| DaisyDisk | CONFIRMED (file) | `~/Library/Application Support/DaisyDisk/License.DaisyDisk` |
| CleanShot X | owned (paid-only app) | in-app activation (Keychain + prefs). SEAT-LIMITED: deactivate/manage old-machine seats at cleanshot.com before activating a new Mac |
| TablePlus | installed; verify in 1Password | in-app; artifacts under `~/Library/Application Support/com.tinyapp.TablePlus` |
| MacWhisper | Pro status unverified | in-app (Gumroad/Lemon Squeezy key) if Pro was purchased |
| Rocket | Pro status unverified | in-app if Rocket Pro was purchased |
| BetterDisplay | no license evidence on AVA (likely free tier) | in-app if Pro is ever purchased |

## Account / subscription sign-in (no key to script)

- 1Password (account + Secret Key from Emergency Kit)
- Backblaze, Dropbox (accounts; Backblaze also re-inherits the backup license per machine)
- Fantastical (Flexibits account)
- HEY, Notion, Notion Calendar, Raycast (Pro), Spotify, Discord, Zulip, Zed
- Docker Desktop (Docker account; business entitlement via org)
- Signal (device-link to phone, not an account password)

## Free — nothing to activate

- Firefox, Google Chrome (profile sync optional)
- Logi Options+, MonitorControl, Rectangle (free tier; Rectangle Pro would be the `rectangle-pro` cask), Cap (account only for cloud features)

## Future activation-script notes

- `op` (1password-cli) is already a declared cask: `op item get <item> --fields license` can feed the defaults/file writes above.
- defaults-based targets (Bartender, iStat Menus) are trivially scriptable; file-based (Hazel, DaisyDisk) are copy-in; in-app-only ones (CleanShot, TablePlus, MacWhisper, Rocket) may be easier done by hand once each.
