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
    # hooks = {
    #   prepare-commit-msg = pkgs.writeShellScript "prepare-commit-msg" ''
    #             # Skip if a message/type is already provided (e.g. -m, --amend, merge)
    #             [ -n "$2" ] && exit 0
    #
    #             DIFF=$(${pkgs.git}/bin/git diff --staged --no-color)
    #             [ -z "$DIFF" ] && exit 0
    #
    #             # Truncate large diffs — 1.5b models degrade quickly beyond ~4k chars
    #             DIFF=$(echo "$DIFF" | head -c 4000)
    #
    #             # Bail fast if Ollama isn't reachable rather than hanging the commit
    #             ${pkgs.curl}/bin/curl -s --connect-timeout 2 http://127.0.0.1:11434 > /dev/null 2>&1 \
    #               || exit 0
    #
    #             RAW=$(
    #               ${pkgs.jq}/bin/jq -n \
    #                 --arg model "qwen2.5-coder:1.5b" \
    #                 --arg prompt "You are a commit message generator. Output ONLY a git commit message, nothing else - no explanation, no preamble, no code fences.
    #
    #     FORMAT:
    #     <type>[optional scope]: <description>
    #
    #     [optional body]
    #
    #     RULES:
    #     - First line: type, optional scope in parens, colon, space, short description (max 50 chars)
    #     - Description must use imperative mood: add not added, fix not fixed
    #     - Valid types: feat, fix, refactor, chore, docs, style, perf, test, build, ci, revert
    #     - Add scope when the change is isolated to one area, e.g. feat(auth): or fix(parser):
    #     - Body is optional - only include if changes need explanation, as plain sentences not bullet points
    #     - Breaking changes: append ! after type/scope, e.g. feat(api)!:
    #
    #     EXAMPLES:
    #     feat(auth): add OAuth2 login support
    #     fix(parser): handle empty input without crashing
    #     refactor(db): extract connection logic into helper
    #     chore: update dependencies
    #
    #     DIFF:
    #     $DIFF" \
    #                 '{model: $model, prompt: $prompt, stream: false}' \
    #               | ${pkgs.curl}/bin/curl -s --max-time 30 -X POST http://127.0.0.1:11434/api/generate \
    #                   -H "Content-Type: application/json" \
    #                   -d @- \
    #               | ${pkgs.jq}/bin/jq -r '.response // empty'
    #             )
    #
    #             # Strip markdown code fences and leading blank lines
    #             MESSAGE=$(echo "$RAW" \
    #               | ${pkgs.gnused}/bin/sed '/^[`]\{3\}/d' \
    #               | ${pkgs.gnused}/bin/sed '/./,$!d')
    #
    #             if [ -n "$MESSAGE" ] && [ "$MESSAGE" != "null" ]; then
    #               printf '%s\n\n# AI Generated via Ollama. Edit or delete to cancel.\n' "$MESSAGE" > "$1"
    #             fi
    #   '';
    # };
  };
}
