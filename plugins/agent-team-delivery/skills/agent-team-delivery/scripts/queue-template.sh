#!/usr/bin/env bash
# คิวเดียวต่อรอบ: commit REPORT.md ของ qa (รวมกับ sync ใน push เดียว) แล้ว merge ทีละตัว
# คัดลอกไป scratchpad แก้ REPO/SCRATCH/รายการท้ายไฟล์ แล้วรัน background ด้วย timeout สูงสุด
set -u
REPO="/path/to/repo"; SCRATCH="/path/to/scratchpad"; BASE=${BASE:-develop}; export REPO SCRATCH BASE
M="$(dirname "$0")/merge-chain.sh"   # หรือ path เต็มของ skill
cd "$REPO" || exit 1
report(){ # <pr> <branch> <evidence-dir> <qa-src-dir ใน SCRATCH> <task>
  git fetch -q origin && rm -rf "$SCRATCH/wt-r$1" && git worktree add -q --detach "$SCRATCH/wt-r$1" "origin/$2" || return 1
  ( cd "$SCRATCH/wt-r$1" && mkdir -p "$3" && cp "$SCRATCH/$4/$3/"* "$3/" && git add "$3" &&
    { git diff --cached --quiet || git commit -q -m "docs: บันทึกผล QA ของ $5 (PR #$1)"; } &&
    git merge -q "origin/$BASE" -m "Merge origin/$BASE into $2" && git push -q origin "HEAD:$2" ); local r=$?
  git worktree remove --force "$SCRATCH/wt-r$1"; [ $r -eq 0 ] && echo "#$1 report pushed"; return $r; }

# ตัวอย่าง:
# report 109 feat/X-1-ui docs/evidence/x/X-1 qa109-evidence X-1 || { echo "STOP #109 report"; exit 1; }
# "$M" 109:feat/X-1-ui 110:feat/X-2-api || echo "STOP chain"
