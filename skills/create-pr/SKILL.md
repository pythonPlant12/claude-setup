---
name: create-pr
description: >
  Title and body conventions for an n-dream GitHub pull request: title
  `<JIRA-ID>: <title>`, fixed body template (Description / Type of Change /
  Jira link / Testing / Checklist), draft PR, assignee nikita-n-dream, no
  reviewers. Apply this whenever a PR is created, including from
  superpowers:finishing-a-development-branch, /work-on-task, or a direct
  "create a PR" request. Uses `gh pr create`.
---

# Create PR (n-dream standard)

Produce a pull request that matches the team format exactly. Assumes changes are
already committed and the branch is pushed. If not, commit (logical commits) and
`git push -u origin <branch>` first, then continue.

Requires: `gh` installed & authenticated, `origin` remote, the JIRA task id.

## 1. Title

Format: `<JIRA_TASK_ID>: <concise title>`

Example:
```
ENG-2638: Migrate and redesign the interaction overlay into platform-frontend
```

## Writing rule
Never use em-dashes or en-dashes (`—` / `–`) anywhere in the title or body. Use a
normal hyphen `-` only. Rewrite the sentence if a long dash is tempting.

## 2. Body

Use this exact template. Fill every section.

```markdown
## Description

- <bullet 1>
- <bullet 2>

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Improve Testing
- [ ] Refactoring
- [ ] Other (e.g., performance improvement, CI/CD changes, dependency update, documentation update)

## Jira link

- [<JIRA_TASK_ID>](https://ndream.atlassian.net/browse/<JIRA_TASK_ID>)

## Testing

- [ ] Added automated tests

- <testing bullet(s)>

## Checklist

- [x] I have performed a self-review of my code
- [x] I have ensured this PR does not break existing functionality
- [x] Manually tested

[<JIRA_TASK_ID>]: https://ndream.atlassian.net/browse/<JIRA_TASK_ID>
```

### Description
Convey the GIST and DIRECTION of the change plus the WHY - what a reviewer should
expect, not a line-by-line replay of the diff. Keep it digestible.
- Small/minor change: a short sentence or two of prose, or a single bullet. No
  forced multi-bullet list.
- Larger change: a few bullets (up to ~10 for big PRs), each a theme of the
  change, not every edit. Point to key files/components/functions with
  backticks/links only where it aids understanding.
- May include design links (e.g. Figma) as a sub-list.
Prefer fewer, higher-signal lines over exhaustive coverage.

### Type of Change
Toggle `[x]` the correct type(s) — one or multiple. Leave the rest `[ ]`.

### Jira link
Exactly as shown: `- [<JIRA_TASK_ID>](https://ndream.atlassian.net/browse/<JIRA_TASK_ID>)`.

### Testing
- Check `[x] Added automated tests` only if new automated tests were added.
- List what testing was done. For NEW tests, prefix each bullet with the test
  type and the area:
  - `- [e2e] skoda: ...`
  - `- [unit-test] client-config: ...`
- If NO tests were added, explain why not.

### Checklist
All three items checked `[x]`.

## 3. Assignee

**Assignee (always):** `nikita-n-dream`

Do NOT add reviewers. The PR opens as a draft; reviewers are assigned manually
later when it is marked ready.

## 4. Commands

Always open the PR as a **draft** (`--draft`).

```bash
# create (draft)
PR_URL=$(gh pr create --draft \
  --title "<JIRA_TASK_ID>: <title>" \
  --body "<body from template above>" \
  --assignee nikita-n-dream)

echo "$PR_URL"
```

Write the body to a temp file and pass `--body-file` if it is long/multiline.

## 5. After creating
Report the PR URL. If working a JIRA task, add a comment on the issue linking the
PR.
