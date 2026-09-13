# =============================================================================
# Hermes AI Agent & Local Model Feature
# =============================================================================
# Hermes AI agent (Nous Research) integrated with a local inference backend
# (Ollama) serving a lightweight model (Qwen 2.5 Coder 1.5B) for private,
# fast local tool-calling, coding, and autonomous workflows.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    let
      model = "qwen2.5-coder:1.5b";
      ollamaHost = "127.0.0.1";
      ollamaPort = 11434;

      hermesLauncher = pkgs.writeShellScriptBin "hermes" ''
        export HERMES_API_TIMEOUT="''${HERMES_API_TIMEOUT:-1800}"
        export UV_PYTHON="${pkgs.python3}/bin/python3"
        exec ${pkgs.uv}/bin/uvx --python "${pkgs.python3}/bin/python3" --from hermes-agent hermes "$@"
      '';

      hermesAgentLauncher = pkgs.writeShellScriptBin "hermes-agent" ''
        export HERMES_API_TIMEOUT="''${HERMES_API_TIMEOUT:-1800}"
        export UV_PYTHON="${pkgs.python3}/bin/python3"
        exec ${pkgs.uv}/bin/uvx --python "${pkgs.python3}/bin/python3" --from hermes-agent hermes-agent "$@"
      '';

      hermesConfig = ''
        # Hermes Agent Configuration — Managed via NixOS
        model:
          default: "${model}"
          provider: "custom"
          base_url: "http://${ollamaHost}:${toString ollamaPort}/v1"
          api_mode: "chat_completions"
          context_length: 65536
          ollama_num_ctx: 65536
      '';
    in
    {
      config = {
        environment.systemPackages = [
          hermesLauncher
          hermesAgentLauncher
          pkgs.ollama
          pkgs.uv
        ];

        services.ollama = {
          enable = true;
          host = ollamaHost;
          port = ollamaPort;
          loadModels = [ model ];
        };

        environment.sessionVariables = {
          HERMES_API_TIMEOUT = "1800";
          OPENAI_BASE_URL = "http://${ollamaHost}:${toString ollamaPort}/v1";
        };

        system.activationScripts.hermes-config = ''
                    HERMES_DIR="/home/${config.username}/.hermes"
                    mkdir -p "$HERMES_DIR"

                    CONFIG_FILE="$HERMES_DIR/config.yaml"
                    if [ ! -f "$CONFIG_FILE" ]; then
                      cat << 'EOF' > "$CONFIG_FILE"
          ${hermesConfig}
          EOF
                    fi

                    chown -R ${config.username}:users "$HERMES_DIR"
        '';
      };
    };
}
