# ตั้งค่า Git / GitHub ก่อนเริ่มโปรเจกต์

สิ่งที่ใช้จริงใน medusa-ecom (ตรวจจาก `gh api .../rulesets` 2026-10-27) ทำครั้งเดียวตอนตั้ง repo — การตั้ง ruleset เป็นการเปลี่ยนค่า repo ภายนอก ต้องให้ owner ยืนยันก่อนรัน

## 1. branch และ default
```bash
git checkout -b develop main && git push -u origin develop
gh repo edit --default-branch develop          # PR ใหม่และ clone ใหม่ชี้ develop
gh repo edit --delete-branch-on-merge          # ลบ feature branch หลัง merge (ทางเลือก)
```

## 2. ruleset `develop` — เข้าได้ผ่าน PR เท่านั้น
```bash
gh api -X POST repos/{owner}/{repo}/rulesets --input - <<'JSON'
{
  "name": "develop: integration via PR only",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/heads/develop"], "exclude": [] } },
  "bypass_actors": [],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request", "parameters": {
        "allowed_merge_methods": ["squash", "merge"],
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true } }
  ]
}
JSON
```
- `required_approving_review_count: 0` เพราะ agent ทั้งหมดใช้บัญชีเดียวกับ owner (GitHub ไม่ให้ approve PR ของตัวเอง) — review จริงอยู่ที่ reviewer agent (comment) + ด่าน merge ของ session หลัก
- ถ้ามีคนอื่นในทีมใช้บัญชีแยก ให้ตั้งเป็น 1 และ/หรือเพิ่ม `required_status_checks` ของ CI ใน develop ด้วย

## 3. ruleset `main` — release จาก develop เท่านั้น
```bash
gh api -X POST repos/{owner}/{repo}/rulesets --input - <<'JSON'
{
  "name": "main: release only from develop",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/heads/main"], "exclude": [] } },
  "bypass_actors": [],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request", "parameters": {
        "allowed_merge_methods": ["merge"],
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true } },
    { "type": "required_status_checks", "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [ { "context": "release-source-check" } ] } }
  ]
}
JSON
```

## 4. `.github/workflows/release-gate.yml` (check ที่ main บังคับ)
```yaml
name: Release gate
on:
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened, edited]
jobs:
  release-source-check:
    runs-on: ubuntu-latest
    steps:
      - name: Require PR source branch to be develop
        env:
          HEAD_REF: ${{ github.head_ref }}
          HEAD_REPO: ${{ github.event.pull_request.head.repo.full_name }}
        run: |
          if [ "$HEAD_REPO" != "$GITHUB_REPOSITORY" ]; then echo "::error::PR to main must come from this repo"; exit 1; fi
          if [ "$HEAD_REF" != "develop" ]; then echo "::error::PR to main only from develop (got $HEAD_REF)"; exit 1; fi
```
ต้อง push workflow นี้ (และให้มันรันอย่างน้อยครั้งเดียว) ก่อนสร้าง ruleset ข้อ 3 ไม่งั้น check จะไม่มีชื่อให้เลือก

## 5. ตรวจว่าตั้งครบ
```bash
gh repo view --json defaultBranchRef -q .defaultBranchRef.name      # develop
gh api repos/{owner}/{repo}/rulesets -q '.[].name'                    # ทั้งสอง ruleset
git push origin HEAD:develop   # ต้องถูกปฏิเสธ (ห้าม push ตรง)
```

## 6. CI ที่ควรมีคู่กัน
- `.github/workflows/ci.yml` รันบน `pull_request` เข้า develop/main และ `push` ไป main (ไม่ต้องรันบน push ไป develop — PR ที่ sync แล้วคือด่านแทน)
- job `changes` + `tools/ci/classify-changes.sh` ตัดสิน docs-only / frontend-only เพื่อข้าม job หนัก
- report/trace ของ e2e อัปโหลดเป็น artifact เก็บ 14 วัน
