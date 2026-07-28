{
  system = "aarch64-darwin";
  username = "gort";
  homeDirectory = "/Users/gort";

  hostName = "GROT";
  localHostName = "GROT";
  computerName = "GROT";

  stateVersion = 6;
  homeStateVersion = "25.11";

  # Deferred: Mac App Store installs hung the first bootstrap (sign-in/auth).
  # After signing into the App Store, set true (or delete this line) and
  # re-run a switch to install the MAS apps.
  masApps = false;
}
