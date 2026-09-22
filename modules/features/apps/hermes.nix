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
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.hermes;

      model = "qwen2.5:7b";
      ollamaHost = "100.124.73.101"; # Homeserver Tailscale IP
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
      options.features.hermes.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the Hermes AI agent with local homeserver Ollama integration.";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          hermesLauncher
          hermesAgentLauncher
          pkgs.ollama # Provides CLI client to interact with homeserver
          pkgs.uv
        ];

        # Offload heavy LLM inference to the homeserver to maximize laptop battery
        services.ollama.enable = false;

        environment.sessionVariables = {
          HERMES_API_TIMEOUT = "1800";
          OPENAI_BASE_URL = "http://${ollamaHost}:${toString ollamaPort}/v1";
          OLLAMA_HOST = "${ollamaHost}:${toString ollamaPort}";
        };

        system.activationScripts.hermes-config = ''
          HERMES_DIR="/home/${config.username}/.hermes"
          mkdir -p "$HERMES_DIR"

          cat << 'EOF' > "$HERMES_DIR/config.yaml"
          ${hermesConfig}
          EOF

          chown -R ${config.username}:users "$HERMES_DIR"
        '';
      };
    };
}
