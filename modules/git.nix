# =============================================================================
# Git Configuration
# =============================================================================
{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName = "Ssnibles";
    userEmail = "joshua.breite@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
    hooks = {
      prepare-commit-msg = pkgs.writeShellScript "prepare-commit-msg" ''
        # Skip if a message/type is already provided (e.g. -m, --amend, merge)
        [ -n "$2" ] && exit 0

        DIFF=$(${pkgs.git}/bin/git diff --staged --no-color)
        [ -z "$DIFF" ] && exit 0

        # Truncate large diffs — 1.5b models degrade quickly beyond ~4k chars
        DIFF=$(echo "$DIFF" | head -c 4000)

        # Bail fast if Ollama isn't reachable rather than hanging the commit
        ${pkgs.curl}/bin/curl -s --connect-timeout 2 http://127.0.0.1:11434 > /dev/null 2>&1 \
          || exit 0

        # Pipe JSON directly into curl — no temp file needed
        MESSAGE=$(
          ${pkgs.jq}/bin/jq -n \
            --arg model "qwen2.5-coder:1.5b" \
            --arg prompt "Write a conventional commit message for this diff. One short summary line (max 50 chars), blank line, then bullet points only if needed. Return only the message:\n\n$DIFF" \
            '{model: $model, prompt: $prompt, stream: false}' \
          | ${pkgs.curl}/bin/curl -s --max-time 15 -X POST http://127.0.0.1:11434/api/generate \
              -H "Content-Type: application/json" \
              -d @- \
          | ${pkgs.jq}/bin/jq -r '.response // empty'
        )

        if [ -n "$MESSAGE" ] && [ "$MESSAGE" != "null" ]; then
          printf '%s\n\n# AI Generated via Ollama. Edit or delete to cancel.\n' "$MESSAGE" > "$1"
        fi
      '';
    };
  };
}
