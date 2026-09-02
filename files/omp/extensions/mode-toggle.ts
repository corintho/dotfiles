import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@oh-my-pi/pi-tui";

const EXEC_WRITE_TOOLS: Record<string, true> = {
  bash: true,
  eval: true,
  write: true,
  edit: true,
  task: true,
  hub: true,
  browser: true,
  computer: true,
  debug: true,
};

// Tracks Discuss mode; read by the mode-box shape renderer on every frame.
let discussActive = false;


export default function modeToggle(pi: ExtensionAPI) {
  let removedExecTools: string[] | undefined;
  let prevMode = "none";

    pi.registerComposerShape({
      label: "Box",
      description: "Standard box layout with Discuss mode chip in the status bar",
      style: {
        id: "mode-box",
        sideBorders: true,
        verticalChrome: 2,
        statusAttachment: "top-border",
        bottomBar: "none",
        bottomBarGap: false,
        defaultPromptGutter: undefined,
        defaultPaddingX(paddingX: number) {
          return Math.max(0, paddingX ?? 2);
        },
        sideChromeWidth(paddingX: number) {
          return paddingX + 1;
        },
        renderTop({ box, paddingX, width, borderColor, accentColor, topBorder }: {
          box: { topLeft: string; topRight: string; horizontal: string };
          paddingX: number;
          width: number;
          borderColor(s: string): string;
          accentColor(s: string): string;
          topBorder?: { content: string; width: number };
        }) {
          const left = borderColor(`${box.topLeft}${box.horizontal.repeat(paddingX)}`);
          const right = borderColor(`${box.horizontal.repeat(paddingX)}${box.topRight}`);
          const inner = Math.max(0, width - (paddingX + 1) * 2);
          // Both modes always visible; Discuss uses accent color, Execute uses border color
          const modeChip = discussActive ? accentColor(" Talk ") : borderColor(" Run  ");
          const modeW = 6; // " Talk " === " Run  " === 6 visible chars
          const rawContent = topBorder?.content ?? "";
          const rawW = topBorder?.width ?? 0;
          // Reserve space on right for chip; truncate status gauge if needed
          const statusRoom = Math.max(0, inner - modeW - 1);
          const content = rawW <= statusRoom ? rawContent : truncateToWidth(rawContent, statusRoom);
          const contentW = rawW <= statusRoom ? rawW : statusRoom;
          const fillW = Math.max(0, inner - contentW - modeW);
          return left + content + borderColor(box.horizontal.repeat(fillW)) + modeChip + right;
        },
        renderRow({ box, paddingX, width, borderColor, text, pad, isLastRow, cursorOverflow, imeSafeCursorTail, scrollbarThumb }: {
          box: { bottomLeft: string; bottomRight: string; horizontal: string; vertical: string };
          paddingX: number;
          width: number;
          borderColor(s: string): string;
          text: string;
          pad: string;
          isLastRow: boolean;
          cursorOverflow: number;
          imeSafeCursorTail: boolean;
          scrollbarThumb: boolean;
        }) {
          const rightW = Math.max(1, paddingX + 1 - cursorOverflow);
          if (isLastRow && imeSafeCursorTail) {
            return [
              borderColor(`${box.vertical}${" ".repeat(paddingX)}`) + text,
              borderColor(`${box.bottomLeft}${box.horizontal.repeat(Math.max(0, width - 2))}${box.bottomRight}`),
            ];
          }
          if (isLastRow) {
            const lhs = borderColor(`${box.bottomLeft}${box.horizontal}${" ".repeat(Math.max(0, paddingX - 1))}`);
            const rhs = borderColor(`${" ".repeat(Math.max(0, rightW - 2))}${rightW >= 2 ? box.horizontal : ""}${box.bottomRight}`);
            return [`${lhs}${text}${pad}${rhs}`];
          }
          const scrollChar = scrollbarThumb ? "\u2588" : box.vertical;
          return [borderColor(`${box.vertical}${" ".repeat(paddingX)}`) + text + pad + borderColor(`${" ".repeat(Math.max(0, rightW - 1))}${scrollChar}`)];
        },
        renderBottom() {
          return undefined;
        },
      },
    });

  // Removes exec/write tools and sets "Discuss" in the status bar.
  // Returns true when a state change occurred.
  // Returns false (and syncs status) when no exec tools were active:
  //   — "Discuss" if removedExecTools is set (already in discuss mode)
  //   — "Run"     if removedExecTools is unset (exec tools absent from registry)
  function switchToDiscussion(): boolean {
      const active = pi.getActiveTools();
      const toRemove = active.filter((n) => EXEC_WRITE_TOOLS[n]);
      if (toRemove.length === 0) {
        return false;
      }
      removedExecTools = toRemove;
      pi.setActiveTools(active.filter((n) => !EXEC_WRITE_TOOLS[n]));
      discussActive = true;
      return true;
    }

  // Restores exec/write tools to the active set and clears "Discuss" state.
  // Returns true when tools were added, false when exec tools were already present.
  // Handles both tracked removals (removedExecTools) and untracked harness
  // restrictions (e.g., plan-mode restrictions, process restart with restricted state).
  function switchToRun(): boolean {
    const current = pi.getActiveTools();
    if (!removedExecTools || removedExecTools.length === 0) {
      // No tools tracked for removal. Check for harness-restricted exec/write
      // tools that are registered but missing from the active set.
      const missing = pi
        .getAllTools()
        .map((t) => t.name)
        .filter((name) => EXEC_WRITE_TOOLS[name] && !current.includes(name));
      if (missing.length === 0) {
        discussActive = false;
        return false;
      }
      pi.setActiveTools([...new Set([...current, ...missing])]);
      removedExecTools = undefined;
      discussActive = false;
      return true;
    }
    pi.setActiveTools([...new Set([...current, ...removedExecTools])]);
    removedExecTools = undefined;
    discussActive = false;
    return true;
  }

  // Auto-enter discuss mode on fresh sessions only (not resumes).
  pi.on("session_start", async (_event, ctx) => {
    const branch = ctx.sessionManager.getBranch();

    // Seed prevMode from existing history so turn_start works correctly on resumes.
    const modeEntry = [...branch].reverse().find((e) => e.type === "mode_change");
    prevMode =
      modeEntry && typeof modeEntry === "object" && "mode" in modeEntry && typeof modeEntry.mode === "string"
        ? modeEntry.mode
        : "none";

    if (branch.some((e) => e.type === "message")) {
      // Resume: tool registry is reset on process restart. switchToRun() restores
      // exec tools if the harness left them restricted, or is a no-op (returns
      // false) if they're already present.
      switchToRun();
      return;
    }

    // Defer one tick so the tool registry is populated before we query it.
    ctx.setTimeout(() => {
      if (!switchToDiscussion()) return; // No exec/write tools present; status already synced.
      ctx.ui.notify("Discussion mode", "info");
    }, 0);
  });

  // Auto-restore tools only on the specific plan → none transition.
  // NOTE: this used to listen on "goal_updated", which never fires here — that
  // event belongs to the unrelated autonomous Goal-tracking system (budget/status),
  // not Plan Mode. Plan approval only shows up as a "mode_change" branch entry;
  // "turn_start" is the first extension-observable event after that entry lands,
  // confirmed by tracing a real plan-approve flow end to end.
  pi.on("turn_start", async (_event, ctx) => {
    const branch = ctx.sessionManager.getBranch();
    const modeEntry = [...branch].reverse().find((e) => e.type === "mode_change");
    const currentMode =
      modeEntry && typeof modeEntry === "object" && "mode" in modeEntry && typeof modeEntry.mode === "string"
        ? modeEntry.mode
        : "none";

    if (prevMode === "plan" && currentMode === "none" && switchToRun()) {
      ctx.ui.notify("Plan approved — execution mode", "info");
    }
    prevMode = currentMode;
  });

  pi.registerCommand("discuss", {
    description: "Read-only mode: disable exec/write tools for discussion",
    handler: async (_args, ctx) => {
      if (!switchToDiscussion()) {
        ctx.ui.notify("Already in discussion mode", "info");
        return;
      }
      ctx.ui.notify("Discussion mode — exec/write tools off", "info");
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
      if (discussActive) {
        if (switchToRun()) _ctx.ui.notify("Execution mode — tools restored", "info");
      } else {
        if (switchToDiscussion()) _ctx.ui.notify("Discussion mode — exec/write tools off", "info");
      }
    },
  });
}
