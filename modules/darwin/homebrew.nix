{
  homebrew = {
    enable = false;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    brews = [ ];
    casks = [ ];
    masApps = { };
  };
}
