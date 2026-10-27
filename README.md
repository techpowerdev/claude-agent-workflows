# claude-agent-workflows

Reusable [Claude Code](https://claude.com/claude-code) workflows for shipping software with a team of subagents.

## Plugins

| Plugin | What it gives you |
|---|---|
| [`agent-team-delivery`](plugins/agent-team-delivery) | An orchestrator workflow: the main session plans and dispatches **planner / builder / qa / reviewer** subagents, enforces spec-driven TDD (one task → one small PR), independent review + QA with evidence, a merge gate (review + green CI + QA report), one-by-one merges into `develop`, and protected `main`/`develop` branching with release PRs. Includes the skill, the four agent definitions, prompt templates, a `CLAUDE.md` template, GitHub ruleset setup, and a sequential merge-queue script. |

The workflow text is written in **Thai** (the language of the team that built it); code, commands and file names are English. Rules are tagged 🧑 (set by the project owner) or 🤖 (learned during real multi-agent runs).

## Install

```bash
claude plugin marketplace add techpowerdev/claude-agent-workflows
claude plugin install agent-team-delivery@claude-agent-workflows
```

Then in any project ask Claude to use the `agent-team-delivery` skill (or let it trigger when you start multi-agent work).

### Make it automatic for a team

Add to the project's `.claude/settings.json` (committed), so everyone who opens the repo is prompted to install it:

```json
{
  "extraKnownMarketplaces": {
    "claude-agent-workflows": {
      "source": { "source": "github", "repo": "techpowerdev/claude-agent-workflows" }
    }
  },
  "enabledPlugins": {
    "agent-team-delivery@claude-agent-workflows": true
  }
}
```

## Adapting to a project

Keep project-specific facts (framework, language, test commands, ports, task-id format) in the project's own `CLAUDE.md` — start from `skills/agent-team-delivery/references/claude-md-template.md`. Set up branches and rulesets with `references/git-setup.md` (it changes repository settings, so run it deliberately). Project-level `.claude/agents/*.md` can override the generic agents shipped here.

## Updating

```bash
claude plugin marketplace update claude-agent-workflows
claude plugin update agent-team-delivery@claude-agent-workflows
```

Contributions: open a PR that adds a lesson (with the incident that taught it) or fixes a rule. Bump `version` in `plugins/agent-team-delivery/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.

---

## ภาษาไทยโดยย่อ

ชุด workflow สำหรับให้ Claude Code ทำงานเป็นทีม agent: session หลักวางแผนและสั่งงาน planner / builder / qa / reviewer — spec เป็นตัวตั้ง, TDD, หนึ่ง task ต่อหนึ่ง PR เล็ก, review และ QA แยกอิสระพร้อม evidence, merge เข้า `develop` ทีละตัวเมื่อผ่านด่าน, `main` เป็นของ release และ owner merge เอง ติดตั้งด้วยสองคำสั่งด้านบน แล้วเก็บรายละเอียดเฉพาะโปรเจกต์ไว้ใน `CLAUDE.md` ของแต่ละโปรเจกต์

## License

MIT — see [LICENSE](LICENSE).
