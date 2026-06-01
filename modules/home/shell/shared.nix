{
  sharedAliases = {
    v = "nvim";
    c = "clear";
    y = "yazi";
    rebuild = "nh os switch";
    hm = "nh home switch";
    update = "nh os switch --update";
    clean = "nh clean all";
    cat = "bat --paging=never --style=plain";
    ls = "eza --group-directories-first --icons=auto";
    ll = "eza -lah --group-directories-first --icons=auto --git";
    lt = "eza --tree --level=2 --icons=auto";
    du = "dust";
    df = "duf";
    ps = "procs";
    find = "fd";
    grep = "rg";
    rga = "ripgrep-all";
    sed = "sd";
    tldr = "tlrc";
    td = "tlrc";
    http = "xh";
    watch = "watchexec";
    gdiff = "git diff";
    j = "just";
    pp = "petpick";
    nf = "nix flake";
    nfu = "nix flake update";
    nd = "nix develop";
    nb = "nix build";
    ns = "nix search nixpkgs";
    fmt = "nixfmt";
    mng = "manage-nixos";
    ":q" = "exit";
    lg = "lazygit";
    ff = "microfetch";
    get-class = "niri msg windows";
  };

  sharedEnv = {
    FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
    FZF_DEFAULT_OPTS = "--height=45% --layout=reverse --border --info=inline";
  };
}
