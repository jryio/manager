{
  system = "aarch64-darwin";
  username = "CASE";
  homeDirectory = "/Users/CASE";

  hostName = "AVA";
  localHostName = "AVA";
  computerName = "AVA";

  stateVersion = 6;
  homeStateVersion = "25.11";

  # AVA's GUI apps predate the cask declarations as manual installs; declaring
  # them here would make the next brew bundle collide with every existing
  # .app. Flip to true after adopting them (brew install --cask --adopt, or
  # --force where versions drifted). Fresh machines default to true.
  guiAppCasks = false;
}
