#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_NAME="select-subagent-profiles"
INSTALL_MODE="symlink"
FORCE=false
DRY_RUN=false
ALL=false
HARNESS_ARGS=()

usage() {
  cat <<'USAGE'
Usage: scripts/install-skill.sh [options]

Install select-subagent-profiles into local agent harness skill directories.

Default targets:
  codex    $CODEX_HOME/skills or ~/.codex/skills
  copilot  $COPILOT_HOME/skills or ~/.copilot/skills

Optional targets:
  claude   $CLAUDE_HOME/skills or ~/.claude/skills
  gemini   $GEMINI_HOME/skills or ~/.gemini/skills
  agents   $AGENTS_HOME/skills or ~/.agents/skills

Options:
  --harness NAME  Install one harness target. Repeatable.
  --all           Install all known harness targets.
  --copy          Copy the skill directory instead of creating a symlink.
  --force         Replace an existing target that points somewhere else.
  --dry-run       Print planned actions without changing files.
  --help          Show this help.

Examples:
  scripts/install-skill.sh
  scripts/install-skill.sh --harness codex --harness copilot
  scripts/install-skill.sh --all --force
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --harness)
      [[ $# -ge 2 ]] || {
        echo "ERROR: --harness requires a value" >&2
        exit 2
      }
      HARNESS_ARGS+=("$2")
      shift 2
      ;;
    --all)
      ALL=true
      shift
      ;;
    --copy)
      INSTALL_MODE="copy"
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

SKILL_DIR="$REPO_ROOT/$SKILL_NAME"
[[ -f "$SKILL_DIR/SKILL.md" ]] || {
  echo "ERROR: missing skill directory: $SKILL_DIR" >&2
  exit 1
}

if [[ "$ALL" == true ]]; then
  HARNESS_ARGS=(codex copilot claude gemini agents)
elif [[ ${#HARNESS_ARGS[@]} -eq 0 ]]; then
  HARNESS_ARGS=(codex copilot)
fi

target_root_for_harness() {
  local harness="$1"
  case "$harness" in
    codex) echo "${CODEX_HOME:-$HOME/.codex}/skills" ;;
    copilot) echo "${COPILOT_HOME:-$HOME/.copilot}/skills" ;;
    claude) echo "${CLAUDE_HOME:-$HOME/.claude}/skills" ;;
    gemini) echo "${GEMINI_HOME:-$HOME/.gemini}/skills" ;;
    agents) echo "${AGENTS_HOME:-$HOME/.agents}/skills" ;;
    *)
      echo "ERROR: unknown harness '$harness'. Known: codex, copilot, claude, gemini, agents" >&2
      return 2
      ;;
  esac
}

is_installed_target() {
  local target="$1"
  if [[ "$INSTALL_MODE" == "symlink" ]]; then
    [[ -L "$target" && "$(readlink "$target")" == "$SKILL_DIR" ]]
  else
    [[ -f "$target/SKILL.md" ]] && cmp -s "$SKILL_DIR/SKILL.md" "$target/SKILL.md"
  fi
}

install_one() {
  local harness="$1"
  local target_root
  target_root="$(target_root_for_harness "$harness")"
  local target="$target_root/$SKILL_NAME"

  if is_installed_target "$target"; then
    echo "ok: $harness already installed at $target"
    return 0
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    if [[ "$FORCE" != true ]]; then
      echo "ERROR: $harness target already exists and does not point to this checkout: $target" >&2
      echo "       rerun with --force to replace it" >&2
      return 1
    fi
    if [[ "$DRY_RUN" == true ]]; then
      echo "would replace: $target"
    else
      rm -rf "$target"
    fi
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "would install: $harness -> $target ($INSTALL_MODE)"
    return 0
  fi

  mkdir -p "$target_root"
  if [[ "$INSTALL_MODE" == "symlink" ]]; then
    ln -s "$SKILL_DIR" "$target"
  else
    mkdir -p "$target"
    cp -R "$SKILL_DIR/." "$target/"
  fi

  echo "installed: $harness -> $target ($INSTALL_MODE)"
}

for harness in "${HARNESS_ARGS[@]}"; do
  install_one "$harness"
done
