# Prompt สำเร็จรูป (session หลัก → agent)

แทน `<...>` ทุกตัว `<S>` = scratchpad ของ session

## builder-common.md (เขียนครั้งเดียวไว้ใน `<S>/builder-common.md`)
ใช้เนื้อหาหัวข้อ 4 ของ SKILL.md เป็นรายการ bullet

## builder — task ใหม่
```
Repo: <repo>. Implement task <TASK> ตามแถว <TASK> ใน <spec path> บน origin/develop (AC และกฎที่แถวนั้นอ้าง)
<คำตัดสินของ owner ที่เกี่ยวข้อง ถ้ามี>
ใช้ของ <framework> ไม่ reinvent ระวังไฟล์ที่ PR เปิดอยู่แก้: <#PR (ไฟล์)> — ถ้าต้องแตะไฟล์เดียวกันให้หยุดรายงาน / หรือรอ PR นั้น merge แล้ว merge origin/develop ก่อน push
ถ้า diff เกิน ~400 LOC แบ่งตาม spec โหลด skill <...> ใช้ port <...>, DB <...>, Redis db <...>
อ่านกติการ่วมใน <S>/builder-common.md ก่อนเริ่มและทำตามทุกข้อ (ตรวจ Depends ด้วย gh pr view ถ้ายังไม่ครบให้หยุดรายงาน)
งาน UI ใส่ checklist qa
```

## builder — แก้ตาม review/qa (ส่งด้วย SendMessage ให้ตัวเดิม)
```
reviewer ขอ REQUEST CHANGES PR #<n> (body: <S>/review-body-<TASK>.md อ่านทั้งไฟล์)
Blocker: <ไฟล์:บรรทัด> <อาการ + วิธีทำซ้ำ> แก้: <ทิศทาง> + test ที่ล้มก่อน (TDD) ห้ามแก้ด้วยการเพิ่ม timeout อย่างเดียว
Nits ทำได้ถ้าเล็ก: <...>
ทำใน worktree ใหม่จาก branch เดิม port/DB/Redis เดิม merge origin/develop ครั้งเดียว push ครั้งเดียว อัปเดต PR body (หัวข้อ "แก้ตาม review") รายงานกลับเมื่อ push
```

## qa
```
QA PR #<n> (<TASK>, branch <b>) ใน repo <repo> เทียบ <spec> (<AC list>)
ทำใน worktree ของตัวเอง <S>/wt-qa-<n> ห้าม checkout ใน repo หลัก ใช้ backend <port> / frontend <port> (prod build), DB <db>, Redis db <k>
ปิด server เฉพาะ PID ของตัวเอง/drop DB/ลบ worktree เมื่อเสร็จ ห้ามอ่าน secret จริง (flow ที่ต้องใช้ ดูผล CI แทน)
ตรวจ checklist ใน PR body: <...> + พยายามทำซ้ำ <บั๊กเดิม/ข้อสงสัยของ builder>
หา element ด้วย data-testid ตรวจภาษาด้วย regex
เขียน REPORT.md (ตาราง AC pass/fail) + screenshot (รวมกับที่ PR มี ≤5 PNG ≤300KB ชื่อไม่ซ้ำ) ลงใน <S>/qa<n>-evidence/<evidence-dir>/ (เขียนไม่ได้ให้ส่งเนื้อหากลับ)
ไม่ commit/push รายงานผลต่อ AC
```

## qa — re-test หลังแก้
```
builder แก้ <defect> ของ PR #<n> แล้ว (head <sha>: <สรุปการแก้>) ขอ re-test ใน worktree ใหม่ สภาพแวดล้อมเดิม (<...>) — สำคัญเพราะรอบแรกเจอบั๊กบนเครื่องนี้
รัน QA spec เดิมซ้ำ ≥3 รอบ + e2e ของ PR + regression แล้วอัปเดต REPORT.md (commit ที่ตรวจทั้งสองรอบ, ตาราง defect รอบ1/รอบ2, ลิงก์ CI run จริง) ส่งเนื้อหาฉบับเต็มกลับ
```

## reviewer
```
Review PR #<n> (<TASK>) ใน repo <repo> เทียบ <spec> (แถว <TASK>, <AC/กฎ>) ADR ที่เกี่ยวข้อง และ CLAUDE.md
ตรวจใน worktree ของตัวเอง <S>/wt-review-<n> ห้าม checkout ใน repo หลัก ลบ worktree เมื่อเสร็จ
จุดที่ดูเป็นพิเศษ: <จาก "จุดที่ reviewer ควรดู" ของ builder + ข้อกังวลของ session หลัก + คำตัดสิน owner ที่เกี่ยวข้อง>
รอ CI ทุก job (`gh pr checks <n> --watch`) โพสต์ review `gh pr review --comment` (ห้าม merge) รายงาน verdict APPROVE/REQUEST CHANGES พร้อม blocker
```

## reviewer — re-review สั้น
```
builder แก้ PR #<n> แล้ว (head <sha>: <สรุป>) ขอ re-review สั้นๆ ด้วย git diff/range-diff จาก head เดิม <sha เดิม> (ไม่ checkout ใน repo หลัก)
ดู: blocker หายจริง, test ใหม่ล้มก่อนแก้, ไม่มี scope creep, merge develop ไม่ทำอะไรหลุด รอ CI ทุก job แล้วโพสต์ review รายงาน verdict
```

## planner — รอบอัปเดต spec
```
Repo: <repo>. ทำ spec รอบ <N> (เอกสารล้วน) ใน worktree <S>/wt-plan-r<N> (session หลักเตรียมไว้แล้ว: branch docs/spec-round-<N> จาก origin/develop, รายการ PR ที่ <S>/merged-prs-r<N>.json, <S>/open-prs-r<N>.json)
ห้ามแตะ repo หลัก ADR ใหม่ใช้เลข <ADR-xxx> เท่านั้น
1) บันทึกคำตัดสิน owner (<วันที่>): <รายการ>
2) แปลง follow-up ใน <S>/followups.md เป็น task/AC (one task one PR, Depends ชัด, รวม nit ไฟล์เดียวกัน, ข้ามที่เสร็จแล้วบน develop — ตรวจโค้ดจริง)
3) อัปเดต ROADMAP
ห้ามแก้โค้ด ส่งกลับ: ข้อความ commit, body PR ที่ <S>/pr-body-SPEC-R<N>.md, task ใหม่ + Depends, คำถาม owner พร้อมข้อเสนอ
```

## คำถามถึง owner (AskUserQuestion)
- ≤4 คำถามต่อครั้ง, header สั้น, option แรก "(Recommended)" + เหตุผลในคำอธิบาย, บอกผลกระทบ/ต้นทุนของแต่ละทาง
- ถามเฉพาะเรื่องที่เป็นของ owner (business rule, infra/dependency ใหม่, scope); เรื่องตีความเทคนิคตัดสินเองแล้วแจ้ง
