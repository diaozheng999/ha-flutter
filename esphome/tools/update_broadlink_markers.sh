#!/bin/sh
# Run beside immutable original.json and marked.json on the HA SSH host.
# Only the two existing RF code sets are eligible; unrelated storage must match.
set -eu
mode=${1:?Use canary, all, or restore; optionally --check}
check=${2:-}
case "$mode" in canary|all|restore) ;; *) exit 2 ;; esac
case "$check" in ''|--check) ;; *) exit 2 ;; esac
work=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target=/config/.storage/broadlink_remote_348e892deef9_codes
original="$work/original.json"
marked="$work/marked.json"
hash() { sha256sum "$1" | cut -d ' ' -f 1; }
test "$(hash "$original")" = 95a395f36e58ee09b2df1c0e49c272612751e09646e47d0a7ac9afe65e43f60c
test "$(hash "$marked")" = b7414e34778452c4b683a6b2625ab37d6299740acaa2ad83037fb96cb7b1752f
# Match every non-target value and require the exact original command names.
jq -e --slurpfile original "$original" '
  (.data["rf.study_fan"] | keys) == ($original[0].data["rf.study_fan"] | keys) and
  (.data["rf.bedroom_fan"] | keys) == ($original[0].data["rf.bedroom_fan"] | keys) and
  (.data["rf.study_fan"] | length) == 13 and
  (.data["rf.bedroom_fan"] | length) == 13 and
  (.data["rf.study_fan"] = $original[0].data["rf.study_fan"] |
   .data["rf.bedroom_fan"] = $original[0].data["rf.bedroom_fan"]) == $original[0]
' "$marked" >/dev/null
canary=$(mktemp "$work/canary.XXXXXX")
temp=$(mktemp "$work/replacement.XXXXXX")
trap 'rm -f -- "$canary" "$temp"' EXIT HUP INT TERM
jq --slurpfile marked "$marked" '
  .data["rf.study_fan"].speed_1 = $marked[0].data["rf.study_fan"].speed_1
' "$original" > "$canary"
before=$(hash "$target")
case "$mode" in
  canary) expected="$original"; replacement="$canary"; count=1 ;;
  all) expected="$canary"; replacement="$marked"; count=26 ;;
  restore)
    if jq -e --slurpfile expected "$canary" '. == $expected[0]' "$target" >/dev/null; then
      expected="$canary"
    else
      expected="$marked"
    fi
    replacement="$original"; count=0 ;;
esac
jq -e --slurpfile expected "$expected" '. == $expected[0]' "$target" >/dev/null
# Retain owner/mode and atomically replace within the same filesystem.
cp -p -- "$target" "$temp"
cat "$replacement" > "$temp"
cmp -s -- "$temp" "$replacement"
if test "$check" = --check; then
  printf 'Validated %s: %s marked commands; current SHA256 %s\n' "$mode" "$count" "$before"
  exit 0
fi
sync
test "$(hash "$target")" = "$before"
mv -f -- "$temp" "$target"
sync
cmp -s -- "$target" "$replacement"
printf 'Applied %s: %s marked commands; SHA256 %s\n' "$mode" "$count" "$(hash "$target")"
printf 'Reload only the Broadlink config entry to refresh its cached codes.\n'
