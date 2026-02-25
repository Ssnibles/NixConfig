{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (p: with p; [ lua nix vim bash markdown ]))
      plenary-nvim
      nvim-lspconfig
      blink-cmp
      nvim-autopairs
      telescope-nvim
      oil-nvim
      statuscol-nvim
      smart-splits-nvim
    ];
    extraLuaConfig = ''dofile("/home/josh/NixConfig/nvim/init.lua")'';
  };
}
