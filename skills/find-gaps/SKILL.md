---
name: find-gaps
description: >
  Gap analysis gate that runs BEFORE any implementation of a complex task, a
  Jira ticket, a bug fix with a vague report, or a feature request. Finds what
  the prompt or ticket does not define, separates decisions Claude can make
  from decisions only the user can make, and asks the user the open questions
  before any code is written. Use this skill whenever the user asks to
  implement, build, add, change, migrate, refactor, or fix something and the
  request leaves room for more than one reasonable implementation. Use it even
  when the user does not ask for analysis, even for short prompts such as
  "there is a bug in X, fix it", and always at the start of /work-on-task.
  Skip it only for trivial, fully specified changes (a typo, a one-line edit
  with an exact instruction). When superpowers:brainstorming runs, this skill
  is its investigation step: read the code, then ask all open questions in
  one round.
---

# Find gaps

## Why this skill exists

A short prompt or a thin ticket hides decisions. Without this gate, the agent
finds the decisions mid-implementation and resolves them alone. The result is
code that works but does the wrong thing for the business. The cost of a wrong
guess is a rewrite. The cost of a question is one message.

The rule: **business and behavior decisions belong to the user. Technical
decisions that the codebase already answers belong to Claude.**

## Workflow

Do the phases in order. Do not write or change code before phase 4 is cleared.

### Phase 1. Investigate

Ground the task in the real code before you judge the request.

1. Read the full request: prompt, ticket, comments, linked tickets.
2. Locate every file, function, call site, config, and test the task touches.
   Read them. Do not skim.
3. For a bug: find the root cause and the exact lines. For a feature: map where
   the change lands and what the current behavior is.
4. Write down, for yourself: what is asked, what the code does today, what
   must change.

Tell the user in one or two lines what you found (for a bug: the cause and
location). Then say that you continue with the gap analysis.

### Phase 2. List the gaps

Walk the checklist below against the request and the code. Record each point
the request does not define and the code does not answer.

| Area | Questions to ask yourself |
|---|---|
| Scope | Which cases are in, which are out? One platform or all? One caller or all callers of the changed function? |
| Expected behavior | What must the user see or get in the main case? What is "fixed" or "done"? |
| Edge cases | Empty input, timeout, retry, concurrent calls, old clients, missing data, partial failure. What happens in each? |
| Business rules | Limits, defaults, permissions, pricing, ordering, who is allowed, what is logged. |
| User-facing output | Messages, errors, UI text, analytics events, API response shape. |
| Compatibility | Existing API consumers, stored data, feature flags, rollout, migration. |
| Non-functional | Performance targets, security, privacy, logging level. |
| Verification | How does the user confirm the result? Which tests must exist? |
| Conflicts | Does the request contradict the code, another ticket, or a comment? |

Also list the assumptions the request makes that the code shows to be false.

### Phase 3. Classify each gap

For each gap, decide who owns the answer.

**Claude decides** when all of these are true:
- The codebase, its conventions, or its tests already give the answer.
- The choice is reversible and internal (naming, file layout, helper reuse,
  test structure).
- No reasonable reviewer would want to be asked.

**The user decides** when any of these is true:
- The answer changes what a user, a customer, or an external system sees.
- The answer is a business rule, a limit, a default, a permission, or a policy.
- More than one implementation is reasonable and they differ in behavior,
  cost, or risk.
- The answer is hard to reverse (data migration, API contract, public event).
- The request conflicts with the code or with another source of truth.
- You would otherwise guess.

Make the decisions you own. State them in the report. Do not ask about them.

### Phase 4. Report and ask

If there are no user-owned gaps, say so in one line and continue to
implementation.

If there are user-owned gaps, stop. Use this structure:

```
## Findings
<2-5 lines: cause or landing zone, files, current behavior>

## Decisions I made
- <decision>: <one-line reason grounded in the code>

## Open questions
1. <question>
   - Option A: <behavior> (recommended, because <reason>)
   - Option B: <behavior>
   - Impact if wrong: <one line>
2. ...
```

Rules for the questions:
- Ask only questions whose answer changes the implementation.
- Give concrete options with a recommendation. Do not ask open-ended "what do
  you want?" questions.
- Order by impact. Put the question that blocks the most work first.
- Keep it to the questions that matter. If there are more than six, group
  them by area and ask the blocking ones first.
- When the `AskUserQuestion` tool is available, use it for the questions. Put
  the recommended option first.

Do not start implementation while a user-owned question is open. Do not
implement "the likely answer" in the meantime.

### Phase 5. Confirm and continue

After the user answers:
1. Restate the agreed decisions in a short list.
2. If an answer opens a new gap, ask once more. Do not loop more than needed.
3. Continue with implementation under the agreed decisions. Keep the decision
   list in the PR description or the ticket comment.

## Example

Prompt: "there is a bug in the connection of controller, fix it"

Without this skill: the agent finds a null check, adds a retry, picks a
timeout, and ships.

With this skill:

```
Found it. `ControllerSocket.connect()` (src/controller/socket.ts:142) resolves
before the handshake ack arrives, so the first `send()` is lost on slow
networks. Continuing with the gap analysis.

## Decisions I made
- Keep the fix in `connect()`; all three callers await it already.
- Add a unit test next to the existing socket tests.

## Open questions
1. What must happen when the handshake never completes?
   - A: reject after a timeout and show the existing "connection lost" screen
     (recommended, reuses current error path)
   - B: retry silently up to N times, then reject
   - Impact if wrong: users see either a hang or a wrong error.
2. Which timeout value?
   - A: 5 s, same as `SCREEN_HANDSHAKE_TIMEOUT` (recommended)
   - B: a new value you define
```

## Anti-patterns

- Asking before reading the code. Half the questions disappear after
  investigation.
- Asking about things the codebase already answers.
- Listing every possible gap. List the ones that change the work.
- Starting to code "the easy part" while questions are open. The easy part
  often depends on the answers.
- Burying the questions in a long report. Findings short, questions clear.
