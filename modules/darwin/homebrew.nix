{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    global.brewfile = false;

    taps = [ ];
    brews = [ ];
    casks = [ ];
    masApps = { };
  };
}
