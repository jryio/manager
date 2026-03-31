# 04 Git Configuration

Topic source: `OVERVIEW.md` line 149
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic is the Git client configuration surface: global settings, signing, credential
helpers, conditional includes, tool integrations, and repo-specific identity switching. It
is mostly a Home Manager problem rather than a nix-darwin problem.

## Current State

The repo-backed `~/dotfiles/git/gitconfig` sets Zed as the editor, configures a `gitego
credential` helper, enables GPG signing, and uses multiple `includeIf` rules that point to
`~/.gitego/profiles/*.gitconfig`. Dotbot configs also still reference extra gitconfig
fragments such as `gitconfig.keybase`, `gitconfig.zed`, `gitconfig.jry`, and
`gitconfig.zigg`, but some of those files are missing or external to the repo.

## nix-darwin Surface

The local research did not find a first-class nix-darwin module that is a clean substitute
for the full Git configuration surface. Darwin can still install `git`, `git-lfs`, signing
tools, and other supporting packages, but it is not the right place to encode user-level
include rules and workflow preferences.

## Home Manager Surface

Home Manager fits this topic directly through `programs.git.settings`,
`programs.git.includes`, `programs.git.signing.*`, and `programs.git.lfs.*`. It also exposes
related integrations such as difftastic through a separate module rather than inside
`programs.git`. That gives a direct path to migrating the current `.gitconfig` semantics
into structured declarative config.

## Recommended Split

Keep Git packages and any system-level signing prerequisites in nix-darwin or shared
packages, but put the actual Git configuration in Home Manager. Conditional identity
switching, editor settings, credential helper wiring, and signing policy are all user-space
concerns.

## Migration Notes

Translate the current gitconfig into Home Manager first without changing behavior, then
audit which external include files are still required. Once the `includeIf` layout is
understood, decide whether those identity-specific fragments stay out of band or become
declarative inputs. Do not remove the old flow until the missing files question is resolved.

## Supporting References

- `~/dotfiles/git/gitconfig`
- `~/dotfiles/install-configs/default.conf.yaml`
- `~/dotfiles/install-configs/personal.conf.yaml`
- `~/dotfiles/install-configs/work.conf.yaml`
- `.ai/docs/home-manager-configuration-options.md` for `programs.git.*`
- `.ai/docs/home-manager-configuration-options.md` for `programs.difftastic.git.enable`
- `.ai/docs/nix-darwin-options.md` for package installation only
- `.ai/plan/OVERVIEW.md` lines 149 to 179

## Notes

Git is a good early Home Manager win because it has a clear module surface and very little
need for privileged state. The main risk is not the module mapping; it is the incomplete
view of the external include hierarchy that the current repo assumes exists.
