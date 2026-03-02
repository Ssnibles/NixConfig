{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (p: with p; [
        lua
        nix
        vim
        bash
        markdown
        kotlin-vim
      ]))
      plenary-nvim
      nvim-lspconfig
      blink-cmp
      nvim-autopairs
      telescope-nvim
      oil-nvim
      statuscol-nvim
      smart-splits-nvim
    ];
    # Use builtins.readFile with a relative path so the config is portable
    extraLuaConfig = builtins.readFile ../nvim/init.lua;
  };
}
