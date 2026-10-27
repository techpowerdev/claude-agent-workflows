---
name: agent-team-delivery
description: Workflow สำหรับ session หลักที่ทำหน้าที่ orchestrator ส่งมอบซอฟต์แวร์ด้วยทีม subagent (planner / builder / qa / reviewer) — spec-driven, TDD, หนึ่ง task ต่อหนึ่ง PR, ตรวจแยกอิสระ, merge ทีละตัวผ่านด่าน CI, เก็บ evidence ใช้เมื่อเริ่มโปรเจกต์ที่จะให้ AI ทำงานขนานหลาย agent, เมื่อต้อง dispatch builder หลายตัว, หรือเมื่อต้อง merge PR หลายตัวเข้า integration branch
---

# Agent Team Delivery

กติกาและขั้นตอนที่ใช้จริงในโปรเจกต์ medusa-ecom (2026-10) แยกให้เห็นว่าข้อไหน **owner กำหนด** (🧑) และข้อไหน **ได้จากบทเรียนระหว่างทำงาน** (🤖) ปรับชื่อ branch/คำสั่ง/ภาษาให้เข้ากับโปรเจกต์ใหม่ แต่คงหลักการไว้

ไฟล์ประกอบ:
- `references/git-setup.md` — default branch, ruleset ของ main/develop, release gate, คำสั่งตรวจ
- `references/claude-md-template.md` — โครง CLAUDE.md ที่ต้องมีก่อนเริ่ม
- `references/agent-definitions.md` — นิยาม agent 4 ตัว (`.claude/agents/*.md`)
- `references/dispatch-prompts.md` — prompt สำเร็จรูปสำหรับสั่ง builder / qa / reviewer / planner
- `scripts/merge-chain.sh` + `scripts/queue-template.sh` — คิว merge ทีละตัวพร้อมด่าน CI

---

## 1. บทบาท

| บทบาท | ทำ | ไม่ทำ |
|---|---|---|
| **session หลัก (orchestrator)** | วางแผนลำดับงาน, เช็ก dependency, dispatch agent, รวมผล, commit evidence ของ qa, resolve conflict ตอน sync, merge เข้า integration branch, รายงาน owner | ไม่ถือโค้ดใน context ไม่เขียน feature เอง 🧑 |
| **planner** | spec + AC + task list (one task one PR, คอลัมน์ Depends) + ADR | ไม่เขียนโค้ด 🧑 |
| **builder** | หนึ่ง task, TDD, worktree ของตัวเอง, เปิด PR | ไม่ merge เอง 🧑 |
| **qa** | e2e จากมุมผู้ใช้, screenshot, ตาราง AC pass/fail, หา defect ที่ test ของ builder เลี่ยง | ไม่ commit (ส่งเนื้อหา REPORT กลับ) 🤖 |
| **reviewer** | ตรวจอิสระเทียบ spec/ADR/convention ไม่เห็น context การ build | ไม่ merge 🧑 |
| **owner** | ตัดสินเรื่องที่เป็นของเขา (business rule, infra ใหม่, release) และ merge เข้า `main` | — |

## 2. หลักที่ต่อรองไม่ได้ (🧑 owner)

1. **ไม่สร้างสิ่งที่ framework/platform มีอยู่แล้วขึ้นใหม่** — ตรวจ docs (context7) และ marketplace/integrations ก่อน ถ้าคิดว่าของเดิมไม่พอ → เขียน ADR และรออนุมัติ
2. **ทำตาม convention ของ framework** (ที่วางไฟล์, pattern ของ service/workflow)
3. **ห้าม over-engineering** — ไม่สร้าง abstraction จนกว่าจะใช้จริงสองที่, ไม่เพิ่ม infra ที่ spec/ADR ไม่กำหนด
4. **TDD** — test ที่ fail ก่อน (ต้องเห็น red จริง) → โค้ดน้อยที่สุด → refactor
5. **ไม่มี evidence = ไม่เกิดขึ้น** — PR ลิงก์ spec + ผล test; งาน UI มี `REPORT.md` ของ qa (ตาราง AC + screenshot ≤5 รูป ≤300KB) report/trace เต็มเก็บเป็น CI artifact ไม่ใช่ git
6. **ความปลอดภัยของ write route** — ทุก route ที่สร้าง/แก้ข้อมูลต้อง authenticate; reviewer block ทุกตัวที่ไม่มี
7. **ภาษา** — สนทนา/PR/commit/เอกสารเป็นภาษาของ owner, โค้ดและศัพท์เทคนิคเป็นอังกฤษ, commit ใช้ prefix Conventional Commits
8. **ก่อนเริ่ม task ต้องเช็ก dependency** (คอลัมน์ Depends + PR ที่เปิดอยู่ รวม PR spec/ADR/hotfix) ถ้ายังไม่ merge → ห้ามเริ่ม ห้ามแตก branch จาก PR ที่ยังไม่ merge ห้ามอ่าน spec จาก branch ที่ยังไม่ merge
9. **merge** — session หลัก merge เข้า integration branch (`develop`) เองได้เมื่อครบเงื่อนไขข้อ 6; `main` owner merge เองเท่านั้น
10. **งานขนาน** — งานที่ไม่ติด dependency ให้ทำขนานได้เลย ระหว่างรอ merge เริ่ม task ถัดไปที่ไม่ติด dependency
11. **ถาม owner เฉพาะสิ่งที่เป็นของ owner** — ส่งคำถามพร้อมข้อเสนอแนะ (option แรก = Recommended + เหตุผล) รวบเป็นชุดเดียว

## 2.1 Git และ branching 🧑
ตั้งครั้งเดียวตอนเริ่ม repo ตาม `references/git-setup.md` (ต้องให้ owner ยืนยันก่อนเปลี่ยนค่า repo)

| branch | หน้าที่ | กติกา |
|---|---|---|
| `main` | released เท่านั้น | ห้าม push ตรง/ลบ/force push; เข้าได้ทาง PR `develop → main` เท่านั้น (check `release-source-check`); **owner merge เอง** |
| `develop` | integration + **default branch** | ห้าม push ตรง/ลบ/force push; เข้าได้ทาง PR เท่านั้น; session หลัก merge เมื่อผ่านด่านหัวข้อ 6 |
| `feat/<task-id>-<slug>` | หนึ่ง task | แตกจาก `origin/develop` **ก่อนเริ่มทำเสมอ** (ใน worktree ของ agent), PR เข้า `develop`, ลบหลัง merge |
| `fix/…`, `chore/…`, `docs/…` | hotfix / CI / เอกสาร | กติกาเดียวกับ feature |

**ห้าม** แตก branch จาก feature branch อื่นที่ยังไม่ merge, ห้าม push ตรงเข้า develop/main แม้ ruleset จะยังไม่ได้ตั้ง, ห้าม force push branch ของ PR ที่มีคนตรวจอยู่ (ใช้ merge develop เข้า branch แทน rebase เพื่อให้ reviewer ดู diff ต่อได้)

**Release** 🧑: เมื่อ develop พร้อม → เปิด PR `develop → main` (ชื่อ `release: vX.Y.Z`, changelog จากชื่อ PR ที่ merge ตั้งแต่ release ก่อน) → CI เต็ม → **owner merge** → tag `vX.Y.Z` บน main (+ GitHub Release) agent เตรียม PR/changelog ได้ แต่ไม่ merge และไม่ tag เอง

**Commit/PR**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `test:`) + คำอธิบายภาษาของ owner, ท้าย commit มี Co-Authored-By ของ AI, body PR ตาม template ลิงก์ spec + task id

## 3. วงจรงาน (loop หลัก)

```
owner goal ─▶ planner: spec/AC/tasks/ADR ─▶ review spec ─▶ merge spec
                                                              │
        ┌─────────────────────────────────────────────────────┘
        ▼
  [เลือก task พร้อม] ─▶ builder (worktree, TDD, 1 push) ─▶ PR
        │                                                   │
        │                     ┌──── มี UI ────▶ qa ──────────┤ (ขนานกัน)
        │                     └────────────▶ reviewer ──────┤
        │                                                   ▼
        │                    REQUEST CHANGES / defect ─▶ builder แก้ (1 push) ─▶ re-review/re-test สั้น
        │                                                   ▼
        │                             APPROVE + CI เขียว + REPORT ─▶ คิว merge (ทีละตัว)
        │                                                   ▼
        └──────────── follow-ups/nits ─▶ followups.md ─▶ planner รอบถัดไป
```

### 3.1 เลือกและ dispatch task 🧑🤖
1. ดึงตาราง task + Depends จาก spec บน `origin/develop` และ `gh pr list` (open + merged)
2. เลือก task ที่ dependency merge ครบ **และไม่แตะไฟล์เดียวกับ PR ที่เปิดอยู่** (เช่น checkout ↔ payment, middleware ↔ auth) ถ้าชน → รอ หรือบอก builder ให้รอ PR นั้น merge ก่อน push
3. ขนานได้ ~5–6 builder ต่อรอบ กำหนด **port / DB / Redis db ไม่ซ้ำกัน** ให้แต่ละตัว 🤖
4. ใช้ prompt จาก `references/dispatch-prompts.md` + ไฟล์กติการ่วม `builder-common.md` ใน scratchpad

### 3.2 เมื่อ builder ส่ง PR
- งาน UI → สั่ง **qa และ reviewer พร้อมกัน**; งาน backend ล้วน → reviewer อย่างเดียว
- บันทึก "เสนอ task ใหม่ / nits / เลื่อนไป" ลง `scratchpad/followups.md` ทันที (ใส่ task id + เลข PR)
- ถ้า builder ถามเรื่องที่เป็น **การตีความทางเทคนิค** (เช่น spec อ้างเลข AC ผิด) → session หลักตัดสินเอง + จดให้ planner แก้ spec; ถ้าเป็น **business rule** → ถาม owner

### 3.3 เมื่อ reviewer/qa ส่งผล
- **REQUEST CHANGES / defect** → ส่งกลับ builder ตัวเดิม (SendMessage เพื่อคง context) พร้อม: blocker ตามตัวอักษร, ไฟล์:บรรทัด, ให้ทำ TDD (red ก่อน), ห้ามแก้แค่เพิ่ม timeout, push ครั้งเดียว
- หลังแก้ → **re-review สั้นๆ** (diff จาก head เดิม / `git range-diff`) และ **qa re-test เฉพาะ defect + regression** บนสภาพแวดล้อมเดิมที่เจอบั๊ก 🤖
- APPROVE → เขียน `REPORT.md` จากเนื้อหาที่ qa ส่งมา ลง `scratchpad/qa<PR>-evidence/<evidence-dir>/` แล้วเข้าคิว merge

### 3.4 รอบ planner
- เมื่อ follow-ups สะสมพอ หรือ owner ตัดสินใจใหม่ → planner อัปเดต spec/ADR/ROADMAP เป็น PR เอกสารเดียว
- planner ไม่มี shell → session หลักสร้าง worktree + ดึงรายการ PR ให้ก่อน แล้ว commit/push/เปิด PR เอง 🤖
- แก้ ADR ที่ accepted แล้ว = เพิ่มภาคผนวกลงวันที่และที่มาเท่านั้น และแจ้ง owner 🤖
- กำหนดเลข ADR/ชื่อไฟล์ให้ planner แต่ละตัวชัด (เคยได้ ADR เลขซ้ำ) 🤖
- reviewer ตรวจ spec PR ด้วย: ตรงคำตัดสินของ owner เป๊ะ, ตรงกับโค้ดที่ PR อื่นกำลังส่งมอบ, task id ผ่าน regex evidence

## 4. กติกา builder (`builder-common.md`)  🧑🤖
- อ่าน CLAUDE.md + spec/ADR จาก `origin/<integration>` เท่านั้น ยืนยัน Depends ซ้ำด้วย `gh pr view`
- worktree ของตัวเองใน scratchpad (ชื่อมี task id) branch `feat/<task-id>-<slug>` **ห้าม checkout ใน repo หลัก**
- TDD; โหลด skill ของ framework ก่อน; ใช้ context7 ตรวจ API แทนการเดา
- เครื่องรับ integration พร้อมกันได้น้อย → รันเฉพาะ test file ของตัวเอง + unit + build/typecheck/lint; ชุดเต็มให้ CI
- **merge/rebase integration branch ครั้งเดียวก่อน push และ push ครั้งเดียว** (ทุก push รัน CI เต็มและ cancel run ก่อนหน้า) 🤖
- diff < ~400 LOC; ถ้าเกินให้แบ่งตาม spec (เช่น backend route / admin UI) หรืออธิบายเหตุผลใน PR (test/evidence ไม่นับรวมโค้ดจริง)
- ไฟล์ชั่วคราวใน scratchpad ชื่อมี task id (`pr-body-<TASK>.md`) 🤖
- ปิด server **เฉพาะ PID ของตัวเอง**, drop DB, flush Redis db, ลบ worktree เมื่อเสร็จ 🤖
- ห้ามอ่าน secret จริง (ใช้ key ปลอมในเครื่อง; flow ที่ต้องใช้ key จริงให้ CI พิสูจน์) 🤖
- คำสั่งถูกปฏิเสธสิทธิ์ → รายงานกลับ ห้ามหาทางอ้อม
- รายงานกลับ: เลข PR, สรุป, AC ที่ครอบ, ผล test (รวม red ก่อนแก้), จุดที่ reviewer ควรดู, checklist qa (งาน UI), task ที่เสนอ, สถานะเก็บกวาด

## 5. กติกา qa และ reviewer 🤖
**qa**
- worktree ของตัวเอง, **prod build** (build + start) ทั้งสองฝั่ง, port/DB/Redis แยก
- หา element ด้วย `data-testid` ไม่ match ข้อความ; ตรวจภาษาด้วย regex อักษร
- พยายาม **ทำซ้ำบั๊กเดิมด้วยวิธีของ qa ครั้งก่อน** และหาเงื่อนไขที่ test ของ builder เลี่ยง (เช่น สร้าง data ผ่าน API แทน UI) — นี่คือที่ qa จับบั๊กจริงได้
- edge case: กดซ้ำ, สองแท็บ, ค่าผิดรูป, ขอบ stock, มือถือ 320/375px
- ส่ง `REPORT.md` เป็นข้อความกลับ (harness ไม่ให้เขียน) + screenshot ใน `scratchpad/qa<PR>-evidence/...` ชื่อไม่ซ้ำกับของ PR รวม ≤5 รูป
- QA spec ที่พึ่ง `docker exec` ไม่ commit — แต่ส่งให้ builder ใช้เป็น failing test ได้

**reviewer**
- worktree ของตัวเอง (หรือ `git diff` จาก fetch) **ห้าม checkout ใน repo หลัก**
- ตรวจ: reinvent framework?, scope creep, over-engineering, test ขาด/ไม่ fail ก่อนแก้ (ลองย้อน src กลับแล้วรัน test), auth/ownership, ตรงคำตัดสิน owner, convention
- รอ CI ทุก job จบ (`gh pr checks <n> --watch`) แล้วโพสต์ review เป็น comment ภาษาของ owner — ห้าม merge
- verdict: APPROVE / REQUEST CHANGES + blocker (ไฟล์:บรรทัด, ทำซ้ำอย่างไร, แก้อย่างไร) + nits แยกชัด

## 6. ด่าน merge 🧑🤖
merge เข้า integration branch ได้เมื่อครบ **ทุกข้อ**:
- [ ] reviewer APPROVE ไม่มี blocker (ถ้าแก้หลัง APPROVE → re-review สั้น รวมถึงการ resolve conflict ที่ session หลักทำเอง)
- [ ] CI ทุก job `SUCCESS` หรือ `SKIPPED` ตามกติกา path filter — ค่าว่าง = ยังรัน ไม่ใช่ผ่าน
- [ ] งาน UI มี `REPORT.md` ของ qa (commit ลง branch รวมกับการ sync ใน push เดียว)
- [ ] dependency merge ครบ, PR ไม่ CONFLICTING
- [ ] PR ถูก sync กับ integration branch ล่าสุดแล้ว CI เขียวบน base นั้น (PR สองตัวที่เขียวแยกกันอาจพังเมื่อรวม)

วิธีทำ (`scripts/`):
- **merge ทีละตัวตามลำดับ critical path**: sync → รอ CI → merge → ตัวถัดไป (ข้าม sync ถ้า integration เปลี่ยนแค่เอกสาร)
- **รวมทุก PR ในสคริปต์เดียว** รันเป็น background ด้วย timeout สูงสุด (2 ชม.) — background default ถูก kill ที่ 30 นาที และสคริปต์ที่รอกันด้วย `pgrep` จะวิ่งต่อทันทีเมื่อตัวหน้าถูก kill
- retry `gh` (เคยล้ม EOF) และห้ามแก้ไฟล์สคริปต์ระหว่างที่รันอยู่
- conflict → session หลัก resolve เอง: เก็บทั้งสองฝั่ง แล้วรัน unit + build + typecheck (+ lint) ก่อน push, แล้วให้ reviewer ดู commit merge สั้นๆ
- auto-mode classifier บล็อก merge (review เป็น comment ไม่ใช่ GitHub Approve) → หยุด แจ้ง owner สั้นๆ พร้อมตารางว่าแต่ละ PR ครบเงื่อนไขแล้ว ไม่หาทางอ้อม
- แจ้ง owner ทุกครั้งที่ merge

**integration branch แดง** (PR ที่ sync ล่าสุดล้มด้วยเหตุที่ไม่ใช่โค้ดตัวเอง) → หยุด merge ทั้งหมด, สั่ง builder หยุด push, อ่าน log จริงก่อนโทษ PR (เช่น OOM/exit 134 ≠ test ล้ม), ทำ hotfix ก่อน

## 7. ประหยัด CI 🧑🤖
- PR เอกสารล้วนรันแค่ lint; PR ที่แก้แค่ frontend ข้าม job backend (กติกาใน `classify-changes.sh`)
- ไม่รัน CI ซ้ำบน push ไป integration branch (PR ที่ sync แล้วคือด่านแทน)
- builder push ครั้งเดียว, แก้ review ให้ครบแล้ว push ครั้งเดียว
- commit REPORT รวมกับ sync ใน push เดียว

## 8. การสื่อสารกับ owner 🧑🤖
- ตอบเป็นภาษาของ owner, สั้น, ตาราง/bullet, บอกสถานะ "merge แล้ว / ในคิว / กำลังตรวจ / builder ทำอยู่"
- เมื่อ owner ถาม "ถึงไหนแล้ว" → สรุปตามตารางนั้น ไม่เดาผลของ agent ที่ยังรัน
- คำถามถึง owner: รวบเป็นชุด, option แรก Recommended + เหตุผล, บอกผลกระทบของแต่ละทาง; ถ้า owner ขอ clarify → ส่งใหม่พร้อมข้อเสนอแนะที่ละเอียดขึ้น
- บันทึกคำตัดสินพร้อมวันที่ลง followups → planner บันทึกลง spec
- ใช้งานถึง limit → หยุด agent ที่รันอยู่ (ไม่ให้เผาโควตา) บอกสิ่งที่เสร็จ/ค้าง แล้ว resume ด้วย SendMessage เมื่อกลับมา

## 9. หน่วยความจำของโปรเจกต์
- `docs/spec/*.md` (source of truth), `docs/decisions/ADR-*.md`, `docs/ROADMAP.md`, PR ที่เปิดอยู่ — session ใหม่อ่านสี่อย่างนี้แล้วทำต่อได้
- บทเรียนใหม่ → เพิ่มใน CLAUDE.md หัวข้อ "บทเรียนที่ต้องไม่ทำผิดซ้ำ" (ผ่าน PR docs) + memory
- `scratchpad/followups.md` = คิวงานสำหรับ planner รอบถัดไป

## 10. ข้อผิดพลาดที่เคยเกิด (อย่าทำซ้ำ) 🤖
- เริ่ม task ก่อน dependency merge → builder ต้องหยุดกลางทาง
- เชื่อ reviewer ที่ดูผิดไฟล์ (เช่น บอกว่าไม่มี Redis locking ทั้งที่อยู่ใน infra module) → ตรวจโค้ดเองก่อนส่งเรื่องให้ owner
- builder บอก "ทำซ้ำบั๊กไม่ได้" แต่ qa ทำซ้ำได้บน prod build (race ขึ้นกับความเร็วเครื่อง) → ให้ qa ลองวิธีเดิมเสมอ
- ADR ตั้งอยู่บนข้อเท็จจริงผิด → reviewer จับได้ ต้องถาม owner ใหม่พร้อมข้อเท็จจริงที่ถูก
- resolve conflict config ผิดจน module หลุด → มี unit test ตรวจรายการ module + รัน build ก่อน push
- regex ของ evidence ไม่รับ task id รูปแบบใหม่ → กำหนดรูปแบบ id ใน spec และให้ planner ตรวจ
