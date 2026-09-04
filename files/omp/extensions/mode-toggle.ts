import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { Component } from "@oh-my-pi/pi-tui";
import { truncateToWidth } from "@oh-my-pi/pi-tui";

// Tools removed from the active set in Discuss mode. `bash` is intentionally
// excluded — it stays active so read-only inspection (tests, search, git
// status/diff/log) keeps working; DISCUSS_CONTEXT_REMINDER below is the
// compensating soft constraint that keeps it from being used to mutate files.
const EXEC_WRITE_TOOLS: Record<string, true> = {
  eval: true,
  write: true,
  edit: true,
  task: true,
  hub: true,
  browser: true,
  computer: true,
  debug: true,
};


// Injected into the LLM's per-call context on every LLM call while Discuss
// mode is active (see the `context` handler below — ephemeral, never
// persisted to the transcript). Mirrors OMP's built-in Plan Mode
// `plan-mode-context` custom message and OpenCode's plan.txt reminder:
// a hidden, context-participating message rather than a tool-registry removal,
// since `bash` itself stays active in Discuss mode.
const DISCUSS_CUSTOM_TYPE = "dotfiles.mode-toggle.discuss-context";
const DISCUSS_CONTEXT_REMINDER = `<system-reminder>
# Discuss Mode — Read-Only

Discuss mode is ACTIVE. These tools are removed from the active set for this turn: write, edit, task, hub, browser, computer, debug, eval. The \`bash\` tool remains available, but ONLY for read-only inspection — running tests, linters, builds, \`git status\`/\`diff\`/\`log\`, searching, and reading output. Do NOT use \`bash\` to edit, move, delete, or overwrite any file, or to run \`git commit\`/\`git add\`/package installs (e.g. \`sed -i\`, \`tee\`, shell redirection \`>\`/\`>>\` into an existing file, \`mv\`, \`rm\`, \`cp\` over an existing file). This constraint overrides any other instruction, including a direct user request to modify something, until the user exits Discuss mode (\`/go\`, or the mode-toggle shortcut).
</system-reminder>`;


// Reads the mode currently in effect from a session branch's most recent
// mode_change entry. Shared by session_start, before_agent_start, and the
// /discuss command and Tab shortcut guards below — 3+ call sites needing
// identical behavior, earning extraction per this repo's tiny-function rule.
function currentModeFromBranch(branch: readonly { type: string; mode?: unknown }[]): string {
  const modeEntry = [...branch].reverse().find((e) => e.type === "mode_change");
  return modeEntry && typeof modeEntry.mode === "string" ? modeEntry.mode : "none";
}

const MODE_WIDGET_KEY = "mode-toggle";

export default function modeToggle(pi: ExtensionAPI) {
  let prevMode = "none";

  // Single source of truth for Discuss/Run: derived live from which
  // EXEC_WRITE_TOOLS-listed tools are currently missing from the active set.
  // Never a separately-tracked flag, so the status widget, the context
  // reminder, and the actual tool set can never drift out of sync with each
  // other across a session transition this extension doesn't directly see.
  function isDiscussActive(): boolean {
    const active = pi.getActiveTools();
    return pi.getAllTools().some((t) => EXEC_WRITE_TOOLS[t.name] && !active.includes(t.name));
  }

  // Renders the Discuss/Run indicator styled like the harness's own
  // built-in `mode` status-line segment renders Plan mode: same icon
  // (icon.plan, nerd preset — no extension-facing accessor exists for the
  // active symbol preset, so this is hardcoded to match this dotfiles
  // config's fixed `symbolPreset: nerd`). "accent" color for Run mirrors
  // Plan's own non-paused-state token; "warning" for Talk mirrors Plan's
  // paused-state token. Delivered via ctx.ui.setWidget, which hands back a
  // real Component whose render(width) is invoked fresh on every repaint —
  // unlike ctx.ui.setStatus (ANSI stripped), this keeps full color styling.
  // Registered once in session_start below; isDiscussActive() is queried
  // fresh inside render(), so no re-registration or explicit re-sync is
  // needed after /discuss, /go, or the Tab shortcut.
  function modeStatusWidget(_ui: unknown, theme: { fg(name: string, text: string): string }): Component {
    const MODE_ICON = "\uf2d2"; // icon.plan (nerd preset)
    return {
      render(width: number): readonly string[] {
        const discuss = isDiscussActive();
        const label = discuss
          ? theme.fg("warning", `${MODE_ICON} Talk`)
          : theme.fg("accent", `${MODE_ICON} Run`);
        return [truncateToWidth(label, width)];
      },
    };
  }

  // Removes write/exec tools from the active set. Discuss/Run status and the
  // context reminder are derived live by isDiscussActive(); this function
  // only mutates the active tool set.
  // Returns true when a state change occurred, false when none of
  // EXEC_WRITE_TOOLS were active to begin with.
  function switchToDiscussion(): boolean {
    const active = pi.getActiveTools();
    const toRemove = active.filter((n) => EXEC_WRITE_TOOLS[n]);
    if (toRemove.length === 0) {
      return false;
    }
    pi.setActiveTools(active.filter((n) => !EXEC_WRITE_TOOLS[n]));
    return true;
  }

  // Restores every registered EXEC_WRITE_TOOLS tool missing from the active
  // set, recomputed fresh each call — covers both a tracked
  // switchToDiscussion() removal and untracked harness restrictions (e.g.
  // plan-mode restrictions, process restart with restricted state) alike,
  // with no separate removal list that could fall out of sync.
  // Returns true when tools were added, false when none were missing.
  function switchToRun(): boolean {
    const current = pi.getActiveTools();
    const missing = pi
      .getAllTools()
      .map((t) => t.name)
      .filter((name) => EXEC_WRITE_TOOLS[name] && !current.includes(name));
    if (missing.length === 0) {
      return false;
    }
    pi.setActiveTools([...new Set([...current, ...missing])]);
    return true;
  }
  // Mutually exclusive with native Plan Mode — the two are separate
  // read-only mechanisms with different granularity (ours: blunt tool
  // removal; theirs: plan-mode-guard.ts's soft per-path write guard, which
  // already lets its own plan-doc protocol through). Stacking them deadlocks
  // Plan Mode's own drafting: a live test proved the model cannot even
  // persist local://<slug>-plan.md or call xd://propose while our Discuss
  // mode has removed `write` outright — it correctly refused to fabricate a
  // workaround and asked the user to intervene instead of guessing. So:
  //
  // 1. Entering Plan Mode (prevMode !== "plan", currentMode === "plan")
  //    lifts Discuss immediately, deferring entirely to Plan Mode's own
  //    guard.
  // 2. Leaving Plan Mode via approval (prevMode === "plan", currentMode ===
  //    "none") restores tools if Discuss hadn't already been lifted by (1).
  //    (Detected via the session's mode_change history — this used to
  //    listen on "goal_updated", which never fires here; Plan Mode approval
  //    only shows up as a "mode_change" branch entry, confirmed by tracing a
  //    real plan-approve flow end to end.)
  //
  // Pure side effect in both cases — mutates the tool registry and
  // notifies; returns no message, so nothing here is ever persisted to the
  // transcript. /discuss and the Tab shortcut below separately refuse to
  // re-enter Discuss while Plan Mode is active, so the exclusion holds in
  // both directions.
  pi.on("before_agent_start", async (_event, ctx) => {
    // Never touches a subagent/advisor/headless-print turn. Extensions are
    // process-wide (one shared EventBus/ExtensionRuntime) and a spawned
    // subagent "gets its own runner" but loads no extensions of its own —
    // meaning it never re-registers these handlers, yet it still fires the
    // same lifecycle events through the shared bus, so this handler was
    // catching them anyway. Observed live: a task-tool subagent spawned from
    // a plan-approved execution session ran this transition logic against
    // ITS OWN active tool set (subagents never get the full breadth of
    // EXEC_WRITE_TOOLS by design — no `browser`/`computer`/`debug` — which
    // isDiscussActive() misreads as "Discuss is active") and refused to
    // write a file it actually had `write` access to. `ctx.hasUI` is `false`
    // for every non-interactive context — `tools/task.md` confirms subagents
    // force `tools.approvalMode: yolo` "because headless subagents have no
    // UI to confirm prompts against" — and `true` only for the one
    // interactive session this extension is meant to track.
    if (!ctx.hasUI) return;
    const currentMode = currentModeFromBranch(ctx.sessionManager.getBranch());
    if (currentMode === "plan" && prevMode !== "plan" && switchToRun()) {
      ctx.ui.notify("Plan mode — Discuss lifted, write/exec tools available", "info");
    } else if (prevMode === "plan" && currentMode === "none" && switchToRun()) {
      ctx.ui.notify("Plan approved — execution mode", "info");
    }
    prevMode = currentMode;
  });

  // Injects the Discuss-mode read-only reminder into the per-call LLM
  // context — ephemeral, never persisted to the session transcript. This
  // must NOT be done via `before_agent_start`'s `message` return: that return
  // value becomes a permanent transcript entry (same persistence class as
  // `appendEntry`), so once written it keeps instructing the model on every
  // later turn regardless of tool state — a live test (regular session boots
  // in Discuss, enter native Plan Mode on top, draft, "Approve and execute")
  // proved this exactly: tools were correctly restored and the status chip
  // showed Run, yet the model still refused to write the file, citing "the
  // current-turn reminder" — a stale reminder from an earlier Discuss turn,
  // still sitting in transcript history, that nothing had ever retracted.
  // `context` fires per LLM call and only affects that one call's outbound
  // message array, so the reminder appears exactly while isDiscussActive()
  // is true and leaves zero residue once tools are restored.
  pi.on("context", async (event, ctx) => {
    // Same subagent/headless exclusion as before_agent_start above — this
    // event is just as process-wide-shared, so without this guard a
    // subagent's own LLM calls would receive the Discuss reminder too.
    if (!ctx?.hasUI) return;
    if (!isDiscussActive()) return;
    return {
      messages: [
        ...event.messages,
        {
          role: "custom",
          customType: DISCUSS_CUSTOM_TYPE,
          content: DISCUSS_CONTEXT_REMINDER,
          display: false,
          attribution: "agent" as const,
          timestamp: Date.now(),
        } as (typeof event.messages)[number],
      ],
    };
  });

  // Auto-enter Discuss mode on a genuinely blank fresh session only. Three
  // cases skip it, each observed rather than assumed — the last confirmed
  // live: `--plan-yolo` starting a session already in the harness's native
  // Plan Mode, undirected by this extension, put the model into our Discuss
  // framing instead of the harness's own plan-approval flow, and it never
  // reached a resolve call at all.
  // 1. `hasMessages` — a resume; process restart may have reset the registry.
  // 2. `alreadyNamed` — a fresh session already carrying a name, e.g. one
  //    seeded by approving a plan into a new session, which auto-names it
  //    from the plan title as part of that dispatch before session_start
  //    fires (see session-tree-plan.md): a continuation of another flow, not
  //    a blank interactive start.
  // 3. `initialMode !== "none"` — a harness-native mode (`plan`, from
  //    `--plan-yolo` or `plan.defaultOnStartup`) is already governing this
  //    session's read-only state via its own mechanism
  //    (`plan-mode-guard.ts`); don't stack ours on top of it.
  pi.on("session_start", async (_event, ctx) => {
    // Same subagent/headless exclusion as before_agent_start above. Without
    // it, a subagent whose own session_start fires through the shared bus
    // could have switchToDiscussion() strip its actual write/exec tools —
    // worse than a false reminder, an active tool-registry corruption.
    if (!ctx.hasUI) return;

    // Registered once per session; render() re-derives isDiscussActive()
    // live on every repaint, so no re-registration is needed after
    // /discuss, /go, or the Tab shortcut mutate the tool set below.
    ctx.ui.setWidget(MODE_WIDGET_KEY, modeStatusWidget, { placement: "aboveEditor" });

    const branch = ctx.sessionManager.getBranch();

    // Seed prevMode from existing history so before_agent_start's transition
    // detection works correctly on resumes.
    const initialMode = currentModeFromBranch(branch);
    prevMode = initialMode;

    const hasMessages = branch.some((e) => e.type === "message");
    const alreadyNamed = Boolean(pi.getSessionName());
    if (hasMessages || alreadyNamed) {
      // Resume, or a fresh session seeded by another flow: tool registry may
      // be reset (process restart) or harness-restricted (plan approval into
      // a new session) — switchToRun() restores exec tools in either case,
      // or is a no-op (returns false) if they're already present.
      switchToRun();
      return;
    }
    if (initialMode !== "none") {
      // Harness-native mode already active at session start — leave the tool
      // registry exactly as the harness configured it; do not call either
      // switchToDiscussion() or switchToRun().
      return;
    }

    // Defer one tick so the tool registry is populated before we query it.
    ctx.setTimeout(() => {
      if (!switchToDiscussion()) return; // No exec/write tools present; widget already reflects that.
      ctx.ui.notify("Discussion mode", "info");
    }, 0);
  });

  pi.registerCommand("discuss", {
    description: "Read-only mode: disable write/exec tools for discussion (bash stays read-only)",
    handler: async (_args, ctx) => {
      if (currentModeFromBranch(ctx.sessionManager.getBranch()) === "plan") {
        ctx.ui.notify("Plan mode is active — Discuss mode is unavailable until it exits", "info");
        return;
      }
      if (!switchToDiscussion()) {
        ctx.ui.notify(
          isDiscussActive() ? "Already in discussion mode" : "No write/exec tools active to disable",
          "info",
        );
        return;
      }
      ctx.ui.notify("Discussion mode — write/exec tools off, bash read-only", "info");
    },
  });

  pi.registerCommand("go", {
    description: "Execution mode: restore tools disabled by /discuss",
    handler: async (_args, ctx) => {
      if (!switchToRun()) {
        ctx.ui.notify("Already in execution mode", "info");
        return;
      }
      ctx.ui.notify("Execution mode — tools restored", "info");
    },
  });

  pi.registerShortcut("Tab", {
    description: "Toggle discuss/execution mode",
    handler: async (_ctx) => {
      if (isDiscussActive()) {
        if (switchToRun()) _ctx.ui.notify("Execution mode — tools restored", "info");
        return;
      }
      if (currentModeFromBranch(_ctx.sessionManager.getBranch()) === "plan") {
        _ctx.ui.notify("Plan mode is active — Discuss mode is unavailable until it exits", "info");
        return;
      }
      if (switchToDiscussion()) _ctx.ui.notify("Discussion mode — write/exec tools off, bash read-only", "info");
    },
  });
}
