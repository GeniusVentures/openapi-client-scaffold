#!/usr/bin/env bash
# Build and test a consuming app against a ref of this scaffold repo.
#
# Usage: gcs_check.sh <gcs-app-dir> <scaffold-ref>
#   <gcs-app-dir>   the app that holds the scaffold submodule (has scaffold/ and templates/components/)
#   <scaffold-ref>  branch, tag or commit of this repo, for example develop
#
# Prerequisites: a checkout of the consuming app, flutter on PATH, python (override with PYTHON).
#
# What it does to the checkout: fetches this repo into the app's scaffold submodule, checks the ref
# out detached, deletes and re-renders the gitignored lib/generated/chat, then runs pub get,
# analyze and test. On exit the submodule goes back to the commit it started on. Nothing is committed.
#
# Expected summary on a healthy ref: codegen failures 0 of 12, pub get exit 0, 0 app-code analyze
# issues, all tests passing. Issues under scaffold/example are known noise (the example package
# does not resolve inside the consumer).
set -u

APP_ARG="${1:-}"
REF="${2:-}"
if [ -z "$APP_ARG" ] || [ -z "$REF" ]; then
  echo "usage: gcs_check.sh <gcs-app-dir> <scaffold-ref>" >&2
  exit 2
fi

SCAF_REPO="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)" || { echo "cannot find the scaffold repo" >&2; exit 2; }
PY="${PYTHON:-python}"
command -v flutter >/dev/null 2>&1 || { echo "flutter not found on PATH" >&2; exit 2; }
command -v "$PY" >/dev/null 2>&1 || { echo "python not found (set PYTHON)" >&2; exit 2; }

APP="$(cd "$APP_ARG" 2>/dev/null && pwd)" || { echo "app dir not found: $APP_ARG" >&2; exit 2; }
git -C "$APP/scaffold" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || { echo "$APP/scaffold is not a git work tree" >&2; exit 2; }
[ -d "$APP/templates/components" ] || { echo "$APP/templates/components not found" >&2; exit 2; }
[ -z "$(git -C "$APP/scaffold" status --porcelain)" ] \
  || { echo "$APP/scaffold has uncommitted changes; refusing to start" >&2; exit 2; }

BASE="$(git -C "$APP/scaffold" rev-parse HEAD)" || exit 2
OUT="$(mktemp -d)"
cd "$APP/scaffold" || exit 2

# The check moves a submodule that belongs to the consumer, so always put it back.
restore() { git -C "$APP/scaffold" checkout -q --detach "$BASE" 2>/dev/null; echo "submodule restored to $(git -C "$APP/scaffold" rev-parse --short HEAD)"; }
trap restore EXIT

git fetch -q "$SCAF_REPO" "+refs/heads/*:refs/remotes/local-scaffold/*" "+refs/tags/*:refs/tags/*" 2>/dev/null
git cat-file -e "$REF^{commit}" 2>/dev/null || REF="local-scaffold/$REF"
git checkout -q --detach "$REF" || { echo "checkout failed"; exit 2; }
echo "== scaffold at $(git rev-parse --short HEAD)"

cd "$APP" || exit 2
rm -rf lib/generated/chat
mkdir -p lib/generated/chat
GEN_FAIL=0
# Both template dirs: the app's own templates first, then the scaffold's shared ones.
for comp in chat_message_bubble chat_message_code_block chat_message_media chat_message_flow; do
  for kind in "" _cubit _state; do
    "$PY" scaffold/tools/scaffold_codegen/engine.py \
      --template "components/${comp}${kind}.dart.jinja2" \
      --tokens scaffold/design_tokens.json \
      --output "lib/generated/chat/${comp}${kind}.dart" \
      --template-dir "$APP/templates" --template-dir "$APP/scaffold/templates" \
      --vars "templates/components/${comp}_vars.json" >"$OUT/gen.log" 2>&1 \
      || { GEN_FAIL=$((GEN_FAIL+1)); echo "codegen FAIL ${comp}${kind}"; tail -3 "$OUT/gen.log"; }
  done
done

flutter pub get >"$OUT/pub.log" 2>&1; PUB=$?
flutter analyze --no-pub >"$OUT/analyze.log" 2>&1
flutter test --no-pub >"$OUT/test.log" 2>&1

echo "== SUMMARY ref=$REF"
echo "codegen failures (of 12): $GEN_FAIL"
echo "pub get exit: $PUB"
echo "analyze: $(grep -E '^ *(error|warning|info) ' "$OUT/analyze.log" | awk '{print $1}' | sort | uniq -c | tr '\n' ' ') | $(tail -1 "$OUT/analyze.log")"
echo "analyze issues in scaffold/example (baseline noise): $(grep -cE "scaffold[\/]example" "$OUT/analyze.log")"
echo "analyze issues in app code (lib/test): $(grep -E "^ *(error|warning|info) " "$OUT/analyze.log" | grep -vcE "scaffold[\/]")"
echo "test: $(grep -E '^[0-9:+~ -]*(All tests passed|Some tests failed)' "$OUT/test.log" | tail -1)"
tail -1 "$OUT/test.log"
echo "logs: $OUT"
