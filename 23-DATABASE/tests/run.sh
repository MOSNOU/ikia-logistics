#!/usr/bin/env bash
# CC-05 — pgTAP test runner.
# Runs every 23-DATABASE/tests/[0-9]*.sql against the local Supabase Postgres.
# Each file is expected to emit TAP output via pgTAP's plan() / is() / ok().
# A run is considered failed if psql errors out OR any TAP line starts with "not ok".

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DATABASE_URL="${DATABASE_URL:-postgres://postgres:postgres@127.0.0.1:54322/postgres}"

PASS_FILES=0
FAIL_FILES=0
TOTAL_OK=0
TOTAL_NOT_OK=0

for f in "$HERE"/[0-9]*.sql; do
  name="$(basename "$f")"
  echo "=== $name ==="
  if out=$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -f "$f" 2>&1); then
    echo "$out"
    ok_count=$(printf '%s\n' "$out" | grep -cE "^ok " || true)
    not_ok_count=$(printf '%s\n' "$out" | grep -cE "^not ok " || true)
    TOTAL_OK=$((TOTAL_OK + ok_count))
    TOTAL_NOT_OK=$((TOTAL_NOT_OK + not_ok_count))
    if [[ "$not_ok_count" -gt 0 ]]; then
      echo "FAILED: $name ($not_ok_count failing assertion(s))"
      FAIL_FILES=$((FAIL_FILES + 1))
    else
      echo "PASSED: $name ($ok_count assertion(s))"
      PASS_FILES=$((PASS_FILES + 1))
    fi
  else
    echo "$out"
    echo "PSQL ERROR: $name"
    FAIL_FILES=$((FAIL_FILES + 1))
  fi
  echo
done

echo "================================================================"
echo "Files: $PASS_FILES passed, $FAIL_FILES failed"
echo "Assertions: $TOTAL_OK passed, $TOTAL_NOT_OK failed"
echo "================================================================"

exit $FAIL_FILES
