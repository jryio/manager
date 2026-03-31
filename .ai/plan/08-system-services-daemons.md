# 08 System Services & Daemons

Topic source: `OVERVIEW.md` line 318
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary
This topic covers launchd jobs, long-lived background services, and related daemons that
need to start automatically. On macOS that can mean true root daemons, user agents, or
vendor-owned background items such as application helpers.

## Current State
No tracked launchd plist files were found in the repo. The main service-like behavior
visible today is Homebrew formulas with `restart_service: true`, plus shell-level SSH agent
wiring that assumes 1Password. That means the repo does not yet provide a direct declarative
source of truth for launchd jobs even though the overview lists the topic as in scope.

## nix-darwin Surface
nix-darwin exposes a broad launchd surface through `launchd.agents`, `launchd.daemons`, and
`launchd.user.agents`. It is the right place for system daemons and a strong candidate for
any user agents that are tightly coupled to system activation or machine policy. It can also
bridge Homebrew-installed services where a typed Nix service does not exist.

## Home Manager Surface
Home Manager also exposes Darwin `launchd.agents`, which makes it a good owner for purely
user-scoped background jobs that live entirely in the home environment. This is especially
appealing when the service is conceptually part of user config rather than system policy.

## Recommended Split
Put system daemons in nix-darwin. Put user-scoped helper agents in Home Manager when they
are really part of the user environment. Keep vendor-managed background items vendor-managed
unless there is a clear benefit to wrapping them declaratively, because many modern macOS
apps handle their own registration.

## Migration Notes
Start by inventorying the live launchd jobs and deciding which ones are still desired. Then
model the obviously intentional items first, such as persistent local databases or user
helper agents, while leaving vendor login items alone. Only after the desired list is known
does it make sense to choose between `launchd.user.agents` and Home Manager
`launchd.agents`.

## Supporting References
- `~/dotfiles/Brewfile` for `restart_service` formulas
- `~/dotfiles/brewfiles/personal.brewfile` and `work.brewfile`
- `~/dotfiles/shell/zshrc` for 1Password SSH socket assumptions
- `.ai/docs/nix-darwin-options.md` for `launchd.agents`, `launchd.daemons`, and
  `launchd.user.agents`
- `.ai/docs/home-manager-configuration-options.md` for `launchd.enable` and `launchd.agents`
- `.ai/plan/OVERVIEW.md` lines 318 to 342
- Homebrew service state and launchd ownership should not be modeled twice
- Vendor-managed background items often remain partially opaque on modern macOS

## Unknowns
- Which live launchd jobs are still desired and which are stale?
- Should 1Password remain the long-term agent authority?
- For user jobs, should the owner be Home Manager `launchd.agents` or nix-darwin
  `launchd.user.agents`?
- Which vendor-managed background items should remain outside declarative control?
- Which Brewfile is actually authoritative for services?

## Notes
This topic is less about module gaps and more about state discovery. There is ample option
surface in both nix-darwin and Home Manager, but almost no tracked source of truth yet for
which background jobs should exist.




































