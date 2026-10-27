#!/usr/bin/env bash
# merge PR เข้า integration branch ทีละตัวแบบมีด่าน CI
# ใช้: REPO=<path> SCRATCH=<dir> [BASE=develop] merge-chain.sh <pr>:<branch> [<pr>:<branch> ...]
# - sync BASE เข้า branch เฉพาะเมื่อ BASE เปลี่ยนไฟล์ที่ไม่ใช่เอกสารนับจาก merge-base
# - รอ CI ของ PR ครบทุก job (pending/queued = ยังรัน; fail/cancel = หยุด; skipped = ผ่าน)
# - merge (retry เพราะ gh เคยล้ม EOF) แล้วไปตัวถัดไป; conflict/CI แดง → พิมพ์ "STOP #n ..." แล้ว exit 1
# รันเป็น background ด้วย timeout สูงสุด และห้ามแก้ไฟล์นี้ระหว่างรัน
set -u
: "${REPO:?ตั้ง REPO}"; : "${SCRATCH:?ตั้ง SCRATCH}"; BASE=${BASE:-develop}
cd "$REPO" || exit 1

is_docs_only(){ local f; while read -r f; do [ -z "$f" ] && continue
  case "$f" in docs/*|*.md) ;; *) return 1;; esac; done; return 0; }

wait_pr(){ sleep 40; for i in $(seq 1 120); do
    c=$(gh pr checks "$1" 2>/dev/null | awk '{print $2}' | grep -c -E 'pending|queued'); [ "$c" -eq 0 ] && break; sleep 30; done
  ! gh pr checks "$1" 2>/dev/null | awk '{print $2}' | grep -qE 'fail|cancel'; }

merge(){ local m; for i in $(seq 1 15); do m=$(gh pr view "$1" --json mergeable -q .mergeable 2>/dev/null)
    case "$m" in MERGEABLE|CONFLICTING) break;; esac; sleep 10; done
  [ "$m" = MERGEABLE ] || return 1
  for i in 1 2 3 4 5; do [ "$(gh pr view "$1" --json state -q .state 2>/dev/null)" = MERGED ] && return 0
    gh pr merge "$1" --merge >/dev/null 2>&1; sleep 10; done
  [ "$(gh pr view "$1" --json state -q .state)" = MERGED ]; }

# 0 = sync แล้ว (ต้องรอ CI ใหม่), 2 = ไม่ต้อง sync, 1 = conflict
sync(){ git fetch -q origin
  if git merge-base --is-ancestor "origin/$BASE" "origin/$1"; then echo "$1 already up to date"; return 2; fi
  local base; base=$(git merge-base "origin/$BASE" "origin/$1")
  if git diff --name-only "$base" "origin/$BASE" | is_docs_only; then echo "$1: $BASE เปลี่ยนแค่เอกสาร — ข้าม sync"; return 2; fi
  local d="$SCRATCH/sync-chain"; rm -rf "$d"; git worktree add -q --detach "$d" "origin/$1"
  (cd "$d" && git merge -q "origin/$BASE" -m "Merge origin/$BASE into $1" >/dev/null 2>&1 && git push -q origin "HEAD:$1"); local r=$?
  git worktree remove --force "$d"; [ $r -eq 0 ] && return 0 || return 1; }

for arg in "$@"; do n=${arg%%:*}; b=${arg#*:}
  sync "$b"; r=$?
  [ $r -eq 1 ] && { echo "STOP #$n conflict"; exit 1; }
  echo "#$n sync=$([ $r -eq 0 ] && echo pushed || echo skipped)"
  wait_pr "$n" && echo "#$n CI green" || { echo "STOP #$n CI red"; gh pr checks "$n"; exit 1; }
  merge "$n" && echo "#$n merged" || { echo "STOP #$n merge"; exit 1; }
done
