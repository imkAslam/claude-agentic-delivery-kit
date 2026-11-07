# Run state — `.claude/delivery/state.json`

This is the run cursor. The tracker holds the ticket details; this file holds position, gates, attempts, change requests and failures, so a run can resume after `/compact` or in a new session. **Change it only through `.claude/skills/deliver/scripts/delivery-state.sh`**, never by hand. The hooks read it.

```jsonc
{
  "version": 1,
  "lane": "understand",          // understand | plan | build | verify | release | done
  "step": "intake",              // a step id from workflow.md
  "milestone": null,             // "ms-1" … during lane build
  "rounds": {},                  // { "<loop id>": n }; reset when the loop exits
  "gates": {
    "<gate id>": {               // intake | g1 | g2 | mbr:<ms> | acceptance | g3 | ops_ack
      "status": "pending",       // pending | approved | rejected | invalidated
      "decision": null, "approver": null, "ts": null, "notes": null,
      "package": {}              // { "<repo-relative path>": "<sha256>" }
    }
  },
  "change_requests": [],         // { id, gate, paths[], reason, status: open|closed, ts }
  "tickets": {},                 // "<id>": { title, type, role, milestone, size, status, attempts, depends_on[], branch, tracker_ref,
                                 //           bug_of, bugs[], severity, found_in, history[{from, to, ts, note?, forced?}] }
                                 // type: feature | chore | spike | bug   size: S | M | L
                                 // status: backlog | ready | in_progress | in_review | changes_requested | approved | done | verified
                                 //         | reopened | blocked | cancelled   (transitions: tracker skill → "Status lifecycle")
  "failures": [],                // { ticket, role, attempts, report, ts }
  "notes": [],                   // { ts, text }, e.g. skipped steps and their reasons
  "messages": [],                // { id: "M-n", from, to, type, re, body, blocking, status: open|answered|closed, answer: {from, body, ts}, ts }
  "usage": [],                   // [{ agent, model, tokens, step: "<lane>/<step>", ts }]  (delivery-state.sh usage add; cost.md)
  "agents": {},                  // { "<key, e.g. ticket:T-004 or discovery:product-manager>": "<agent id for SendMessage>" }
  "release": { "name": null, "artifact": null, "environment": null },
  "validated_at": null,
  "updated_at": null
}
```

## Invariants the hooks rely on
- `delivery-state.sh verify g3` passes (approved + every package hash matches) → `guard-prod.sh` allows production triggers and release-tag pushes.
- A path in any `approved` gate package is editable only while an `open` change request lists it (`guard-gates.sh`).
- `g2` approved → every path matching `project.json → contracts.paths` is read-only for everyone except `solution-architect`, and for it only under an open CR on `g2` (`guard-boundary.sh`).
- The SessionStart hook prints the `summary` output after startup, resume and compaction.
