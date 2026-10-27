# โครง CLAUDE.md สำหรับโปรเจกต์ที่ใช้ agent-team-delivery

คัดลอกไปเป็น `CLAUDE.md` ที่ root ของโปรเจกต์ แล้วเติมส่วนใน `<...>`

```markdown
# CLAUDE.md — กฎของโปรเจกต์ (อ่านก่อนเริ่มทุก session)

## Language
- สนทนากับ owner เป็น<ภาษา> ทุก agent ด้วย
- เขียนเป็น<ภาษา>: ชื่อ/เนื้อหา PR, commit message (prefix Conventional Commits อังกฤษ), review comment, REPORT.md, เอกสารใน docs/
- คงอังกฤษ: โค้ด, ชื่อตัวแปร/ไฟล์/branch, คำสั่ง, ชื่อ API
- ข้อความ UI: <กติกา เช่น ภาษาเดียวเขียนตรงในโค้ด / i18n>; test หา element ด้วย data-testid เสมอ

## โปรเจกต์นี้คืออะไร
<สร้างบน framework อะไร ขยายอะไร ไม่สร้างอะไรแทน>

## ข้อห้ามที่ต่อรองไม่ได้
1. ห้ามสร้างสิ่งที่ <framework> ทำได้ดีอยู่แล้ว — ตรวจ docs/<spec core> + marketplace ก่อน; ไม่พอ → ADR + อนุมัติ
2. ทำตาม convention ของ <framework> (<ที่วางไฟล์>)
3. ห้าม over-engineering / ห้ามเพิ่ม infra ที่ spec หรือ ADR ไม่กำหนด
4. TDD: test fail ก่อน → โค้ดน้อยที่สุด → refactor (<unit / integration / e2e ใช้ที่ไหน>)
5. <กติกาความปลอดภัย เช่น ทุก write route ต้อง authenticate>
6. ไม่มี evidence = ไม่เคยเกิดขึ้น: PR ลิงก์ spec + ผล test; qa ทำ docs/evidence/<feature>/<task-id>/REPORT.md (session หลัก commit); ≤5 PNG ≤300KB; report/trace เต็มเป็น CI artifact

## Commands
<install / dev / test:unit / test:integration / e2e / lint / typecheck / build / migrate / seed>

## Branching และ PR
- `main` = released, `develop` = integration, feature = `feat/<task-id>-<slug>`
- หนึ่ง PR ต่อหนึ่ง task, diff < ~400 LOC, CI เขียว, body ตาม PR template; agent ที่เปิด PR ห้าม merge เอง
- merge เข้า develop: session หลักทำเมื่อครบ — reviewer APPROVE ไม่มี blocker, CI ทุก job SUCCESS/SKIPPED, งาน UI มี REPORT.md, dependency merge ครบ, ไม่ CONFLICTING; merge ทีละตัวแล้วแจ้ง owner
- merge เข้า main: owner เท่านั้น
- ก่อนเริ่ม task ใหม่: เช็กคอลัมน์ Depends + `gh pr list`; dependency ยังไม่ merge → ห้ามเริ่ม แจ้ง owner

## บทเรียนที่ต้องไม่ทำผิดซ้ำ
<เพิ่มทุกครั้งที่เจอ — ดูหัวข้อ 10 ของ SKILL.md เป็นจุดตั้งต้น>

## Agents (.claude/agents/)
planner / builder / qa / reviewer — session หลักวางแผน มอบหมาย รวมผล ไม่ถือโค้ดใน context

## ความจำของโปรเจกต์
docs/spec/*.md, docs/decisions/ADR-*.md, docs/ROADMAP.md, PR ที่เปิดอยู่

## Definition of Done (ต่อ task)
- [ ] test เขียนก่อนและผ่าน
- [ ] lint/typecheck ผ่าน
- [ ] ติ๊ก AC ใน spec
- [ ] evidence ใต้ docs/evidence/<feature>/
- [ ] PR ไป develop กรอก template ครบ
- [ ] reviewer อนุมัติ
```

## สิ่งที่ควรมีในโปรเจกต์ด้วย
- `.github/pull_request_template.md` — ลิงก์ spec, task id, AC ที่ครอบ, ผล test, checklist qa
- `tools/ci/classify-changes.sh` — ตัดสินว่า PR แก้ docs/frontend/backend เพื่อข้าม job หนัก
- unit test ที่ตรวจ evidence (ชื่อโฟลเดอร์ตรง regex task id, ≤5 PNG, ≤300KB, ไม่มี subfolder)
- unit test ที่ตรวจรายการ module/middleware ใน config (กัน resolve conflict แล้ว module หลุด)
- `.mcp.json` — docs server (context7), browser (playwright), DB (read-only) ตามที่ใช้
