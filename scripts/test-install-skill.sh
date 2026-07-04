#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALLER="$SCRIPT_DIR/install-skill.sh"
SKILL_DIR="$REPO_ROOT/select-subagent-profiles"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_symlink_to_skill() {
  local path="$1"
  [[ -L "$path" ]] || fail "expected symlink at $path"
  [[ "$(readlink "$path")" == "$SKILL_DIR" ]] || fail "expected $path to point to $SKILL_DIR"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

HOME="$tmpdir/home" "$INSTALLER" >"$tmpdir/install-skill-default.out"
assert_symlink_to_skill "$tmpdir/home/.codex/skills/select-subagent-profiles"
assert_symlink_to_skill "$tmpdir/home/.copilot/skills/select-subagent-profiles"
[[ ! -e "$tmpdir/home/.claude/skills/select-subagent-profiles" ]] || fail "default install should not install claude"

HOME="$tmpdir/home-all" "$INSTALLER" --all >"$tmpdir/install-skill-all.out"
for root in .codex .copilot .claude .gemini .agents; do
  assert_symlink_to_skill "$tmpdir/home-all/$root/skills/select-subagent-profiles"
done

mkdir -p "$tmpdir/home-conflict/.codex/skills/select-subagent-profiles"
if HOME="$tmpdir/home-conflict" "$INSTALLER" --harness codex >"$tmpdir/install-skill-conflict.out" 2>"$tmpdir/install-skill-conflict.err"; then
  fail "expected existing non-symlink target to fail without --force"
fi
[[ -d "$tmpdir/home-conflict/.codex/skills/select-subagent-profiles" ]] || fail "conflicting directory should remain without --force"

HOME="$tmpdir/home-conflict" "$INSTALLER" --harness codex --force >"$tmpdir/install-skill-force.out"
assert_symlink_to_skill "$tmpdir/home-conflict/.codex/skills/select-subagent-profiles"

echo "install-skill tests passed"
