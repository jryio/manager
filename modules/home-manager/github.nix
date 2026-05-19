{ config, lib, pkgs, ... }:

{
  programs.gh = {
    enable = true;
    settings = {
      # gitego owns per-identity SSH; gh CLI talks HTTPS so the 1Password
      # SSH agent isn't pulled into gh's auth path.
      git_protocol = "https";
    };
    extensions = with pkgs; [ gh-dash ];
  };

  programs.gh-dash = {
    enable = true;
    settings = {
      defaultSection = "prs";
      prSections = [
        {
          title = "My Pull Requests";
          filters = "is:open author:@me";
        }
        {
          title = "Needs My Review";
          filters = "is:open review-requested:@me";
        }
        {
          title = "Involved";
          filters = "is:open involves:@me -author:@me";
        }
      ];
      issuesSections = [
        {
          title = "My Issues";
          filters = "is:open author:@me";
        }
        {
          title = "Assigned";
          filters = "is:open assignee:@me";
        }
      ];
    };
  };
}
