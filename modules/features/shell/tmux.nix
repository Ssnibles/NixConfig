# Tmux setup.
# Plugins, session management, window picking, and a user service.
_: {
  flake.nixosModules.shared =
    {
      pkgs,
      config,
      ...
    }:
    let
      c = config.theme.colours;

      scripts = import ./tmux/_scripts.nix { inherit pkgs c; };
      inherit (scripts)
        tmuxJjuiPopup
        tmuxNaviPopup
        tmuxResurrectSave
        tmuxSeshKiller
        tmuxSeshPicker
        tmuxWindowPicker
        tmuxYaziPopup
        ;

      tmuxConfig = import ./tmux/_config.nix {
        inherit
          pkgs
          config
          c
          scripts
          ;
      };

    in
    {
      config = {
        environment.systemPackages = [
          pkgs.sesh
          tmuxWindowPicker
          tmuxResurrectSave
          tmuxSeshPicker
          tmuxSeshKiller
          tmuxYaziPopup
          tmuxJjuiPopup
          tmuxNaviPopup
          pkgs.tmuxPlugins.yank
          pkgs.tmuxPlugins.resurrect
          pkgs.tmuxPlugins.extrakto
          pkgs.tmuxPlugins.tmux-fzf
          pkgs.tmuxPlugins.tmux-floax
          pkgs.tmuxPlugins.jump
          pkgs.yazi
        ];

        programs.tmux = {
          enable = true;
          shortcut = "`";
          keyMode = "vi";
          baseIndex = 1;
          clock24 = true;
          escapeTime = 5;
          terminal = "tmux-256color";
          historyLimit = 50000;

          extraConfig = tmuxConfig;
        };

        # Start tmux at login.
        systemd.user.services.tmux = {
          description = "Tmux terminal multiplexer daemon";
          documentation = [ "man:tmux(1)" ];
          wantedBy = [ "default.target" ];
          environment = {
            # Match the socket directory used by programs.tmux in user shells.
            TMUX_TMPDIR = "%t";
          };
          path = with pkgs; [
            "/etc/profiles/per-user/${config.username}/bin"
            "/run/current-system/sw/bin"
            tmux
            unstable.fish
            sesh
            zoxide
            fzf
            bash
            coreutils
            procps
          ];
          serviceConfig = {
            Type = "forking";
            ExecStart = "${pkgs.tmux}/bin/tmux start-server \\; set-option -s exit-empty off";
            ExecStop = "${pkgs.tmux}/bin/tmux kill-server";
            Restart = "on-failure";
          };
        };

        hjem.users.${config.username}.files = {
          ".config/fish/functions/ta.fish" = {
            clobber = true;
            text = ''
              function ta --description "Smart tmux session manager with sesh"
                  if test (count $argv) -gt 0
                      ${pkgs.sesh}/bin/sesh connect $argv[1]
                  else
                      ${tmuxSeshPicker}/bin/tmux-sesh-picker
                  end
              end
            '';
          };

          ".config/sesh/sesh.toml" = {
            clobber = true;
            text = ''
              [default_session]
              startup_command = "${pkgs.fish}/bin/fish"
            '';
          };
        };

        # Tmux aliases.
        programs.fish.shellAliases = {
          t = "tmux";
          tls = "tmux ls";
        };
      };
    };
}
