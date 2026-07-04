{
  sharedAliases = {
    v = "nvim";
    c = "clear";
    y = "yazi";
    b = "btop";
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
    ":q" = "exit";
    lg = "lazygit";
    ff = "microfetch";
  };

  sharedEnv = {
    FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
    FZF_DEFAULT_OPTS = ''
      --height=60%
      --layout=reverse
      --border=rounded
      --border-label=""
      --info=inline
      --prompt="❯ "
      --pointer="▶"
      --marker="✓"
      --header="╱"
      --padding=1,2
      --margin=0,1
      --scrollbar="│"
      --preview-window=right,50%,border-left
      --bind=ctrl-/:toggle-preview
      --bind=ctrl-j:down,ctrl-k:up
      --bind=ctrl-f:page-down,ctrl-b:page-up
      --bind=ctrl-a:select-all,ctrl-d:deselect-all
      --bind=ctrl-y:accept
      --cycle
      --no-mouse
      --reverse
    '';
  };
}
