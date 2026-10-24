#!/usr/bin/env bash
# Parse-checks every GDScript file we own (not addons). Fails if any file has an error.
# Usage: GODOT_BIN=/path/to/godot tools/check_scripts.sh
set -u
GODOT_BIN="${GODOT_BIN:-godot}"
failed=0
count=0
while IFS= read -r f; do
  count=$((count + 1))
  out="$("$GODOT_BIN" --headless --path . --check-only --script "res://${f#./}" 2>&1)"
  if [ $? -ne 0 ] || echo "$out" | grep -qaE "SCRIPT ERROR|Parse Error"; then
    echo "FAILED: $f"
    echo "$out" | sed 's/\x1b\[[0-9;]*m//g' | grep -aE "ERROR|at:" | head -5
    failed=1
  fi
done < <(find . -name '*.gd' -not -path './addons/*' -not -path './.godot/*' -not -path './build/*' | sort)
echo "Checked $count script(s)."
exit $failed
