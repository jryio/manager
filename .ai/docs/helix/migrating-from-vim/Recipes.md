Includes common solutions to some problems.

## Git Integration (with `lazygit`)
 
Helix comes with basic git integration such as the ability to see which files have been modified on the gutters, and acting on git hunks as text objects. But a more comprehensive git integration can be desired, which is understandable.

Lazygit is the most popular git TUI and you can smoothly integrate it with Helix with the following keymap:

```toml
# helix/config.toml
[keys.normal]
C-g = [
    ":write-all",
    ":insert-output lazygit >/dev/tty",
    ":redraw",
    ":reload-all"
]
```

## Advanced File Explorer (with `yazi`)

Helix includes a basic built-in file explorer `space + e` (workspace directory) and `space + E` (directory of current file).

However, you can also use [`Yazi`](https://github.com/sxyazi/yazi) which is a blazingly fast and extremely powerful explorer written in Rust with tons of features, including media preview (images, documents, videos), advanced search and file manipulation, and more.

You can replace Helix's file explorer keybindings with Yazi that will open file in the same directory using the following keymap.

```toml
[keys.normal.space]
e = [
  ':sh rm -f /tmp/unique-file-h21a434',
  ':insert-output yazi "%{buffer_name}" --chooser-file=/tmp/unique-file-h21a434',
  ':sh printf "\x1b[?1049h\x1b[?2004h" > /dev/tty',
  ':open %sh{cat /tmp/unique-file-h21a434}',
  ':redraw',
]
```

If both Helix and Yazi have mouse support enabled, they will conflict, you can use this trick to reset the mouse state when exiting Yazi and returning to Helix:

```diff
  ':redraw',
+  ':set mouse false',
+  ':set mouse true',
]
```

## Project-wide Search and Replace (with `scooter`)

In helix, you can perform search-and-replace in a file by using <kbd>%</kbd> to select the whole file and then <kbd>s</kbd> to match a regex against the file, placing cursors on each match.

But what if you want to perform a project-wide search and replace? Helix currently doesn't provide that functionality, but there is an external tool called [`scooter`](https://github.com/thomasschafer/scooter) which was created exactly for this purpose. Check it out!

You can create a keybinding to open `scooter` inside of Helix without having to leave the terminal:

```toml
[keys.normal]
C-r = [
    ":write-all",
    ":insert-output scooter --no-stdin >/dev/tty",
    ":redraw",
    ":reload-all"
]
```

For an improved experience with scooter, use the following wrapper script as `scooterhx %{selection}` instead of `scooter --no-stdin`. 

```bash
#!/usr/bin/env bash
printf "\x1b[?2004l" > /dev/tty
args=()
if [[ -n "$1" ]]; then
  args+=(--search-text "$1")
fi
scooter --no-stdin "${args[@]}" >/dev/tty
code=$?
printf "\x1b[?1049h\x1b[?2004h" >/dev/tty
exit $code
```


## Remap Caps Lock to Escape

The <kbd>Esc</kbd> key is quite far away from the home row on most keyboards. Due to this fact, many people remap <kbd>Caps Lock</kbd> to <kbd>Esc</kbd>.

To do this, follow instructions for your operating system.

### Linux

You can use [`keyd`](https://github.com/rvaiya/keyd), which is a modern alternative to `xmodmap` compatible with Wayland and XOrg.

1. Install `keyd` using your system's package manager

1. Start the `keyd` daemon:

   ```sh
   sudo systemctl enable keyd
   ```

1. Place the following in `/etc/keyd/default.conf`

   ```sh
   [ids]
   *
   [main]
   # Maps capslock to escape when pressed and control when held.
   capslock = overload(control, esc)

   # Remaps the escape key to capslock
   esc = capslock
   ```

1. Run `sudo keyd reload` to reload the config set.

### macOS

1. Open _System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys_

1. Map the caps lock key to escape.

### Windows

AutoHotkey is a free and open source scripting language for Windows, primarily useful for remapping keyboard keys in our example.

1. Install AutoHotkey from the [AutoHotkey installation page](https://www.autohotkey.com/download/).

1. Create a new `remap-caps-lock.ahk` file on your desktop.

1. Right-click on the new script file and select `Edit script`.

1. Add this line to the script:

   ```ahk
   CapsLock::Esc
   ```

1. Run the script by double-clicking on it. It will start running in the background.

#### Make it run automatically

1. Press <kbd>Win</kbd> + <kbd>R</kbd> to open the `Run` dialog.
1. Type `shell:startup` and press <kbd>Enter</kbd>.
1. Copy the `remap-caps-lock.ahk` file and paste it into the Startup folder.

The script will run automatically every time you start your computer.


## Integrated Terminal

At the moment, there's no way to open a terminal from within Helix. Despite that, many users prefer using <kbd>Ctrl</kbd> + <kbd>z</kbd> which puts the current process to sleep.

When you run this command from inside Helix, it will be put to sleep. You'll be able to access the terminal again, browse files, and do everything else you usually do.

Once you need to return back to Helix, you can type `fg` in the terminal which will bring Helix back from sleep and resume it exactly where you left it. You can use this to run background processes while using Helix, and other shell commands.

**Use Ctrl + Z to toggle between Helix and Terminal**

If you prefer using <kbd>Ctrl</kbd> + <kbd>z</kbd> to put Helix to sleep, and then use <kbd>Ctrl</kbd> + <kbd>z</kbd> to wake it up again instead of using `fg`, then you can!

Depending on your shell, put a snippet of code into your terminal.

### zsh

Add the following to your `~/.zshrc`:

```sh
# Allow Ctrl-z to toggle between suspend and resume
function Resume {
  fg
  zle push-input
  BUFFER=""
  zle accept-line
}
zle -N Resume
bindkey "^Z" Resume
```

### fish

Add the following to your fish config file:

```sh
bind \cz 'fg 2>/dev/null; commandline -f repaint'
```

This is possible since [fish v3.2.0](https://fishshell.com/docs/3.2/relnotes.html#new-or-improved-bindings).

Source: [Binding CTRL-Z](https://github.com/fish-shell/fish-shell/issues/7152#issuecomment-663575001).

### nushell

As of version `0.103`, nushell has support for background jobs.

Add the following in your config:

```nu
$env.config.keybindings ++= [
  {
    name: "unfreeze",
    modifier: control,
    keycode: "char_z",
    event: {
      send: executehostcommand,
      cmd: "job unfreeze"
    },
    mode: emacs
  }
]
```

### bash

Use [bash-preexec.sh](https://github.com/rcaloras/bash-preexec) to:

- Disable the Ctrl-Z keybinding before printing the prompt
- Enable the Ctrl-Z keybinding before executing a command

This way, we are able to repurpose Ctrl-Z when in a Bash interactive prompt. But any command ran by Bash will still be able to suspend normally with <kbd>Ctrl</kbd> + <kbd>Z</kbd>.

You might need to change this path to your bash-preexec.sh location.

```sh
source ~/.config/bash/bash-preexec.sh
preexec () {
  stty susp '^Z'
}
precmd () {
  stty susp undef
}

# Bind Ctrl-Z to "fg %-" (resume next to last suspended job, or last if only one)
# This binding works like this:
# - If you have one job, Ctlr-Z will toggle in and out of it.
# - If you have more  jobs, "Ctrl-Z Ctrl-Z" will toggle between the last two.
bind '"\C-z":"fg %-\n"'
```

## Continue Markdown Lists / Quotes

If you want list items to continue when you press <kbd>Enter</kbd> or <kbd>o</kbd> and such, you can add this to your config:

```toml
[[language]]
name = "markdown"
comment-tokens = ["-", "+", "*", "- [ ]", ">"]
```

This will also work in other markup language if they use a similar syntax to Markdown's.