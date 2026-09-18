import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";

// Resolve the locally installed opencode version for the Copilot User-Agent.
function opencodeVersion(): string {
  try {
    return execSync("opencode --version", { encoding: "utf8", timeout: 5000 }).trim();
  } catch {
    return "1.18.21"; // fallback if the binary is unavailable
  }
}

// Modern OpenCode Zen client identity (per pi-opencode-fix d2c925c).
const OPENCODE_VERSION = "1.18.31";
const USER_AGENT = `opencode/${OPENCODE_VERSION} ai-sdk/provider-utils/4.0.40 runtime/bun/1.3.14`;
const COPILOT_UA = `opencode/latest/${opencodeVersion()}/cli`;

// Synchronized session/request IDs required by the OpenCode Zen gateway.
const ID_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
let counter = 0;
let lastTimestamp = 0;

function generateId(prefix: "ses" | "msg", descending: boolean, timestamp = Date.now()): string {
  if (timestamp !== lastTimestamp) {
    lastTimestamp = timestamp;
    counter = 0;
  }
  counter++;

  const current = BigInt(timestamp) * 0x1000n + BigInt(counter);
  const value = descending ? ~current : current;
  const timeHex = Array.from({ length: 6 }, (_, index) =>
    Number((value >> BigInt(40 - 8 * index)) & 0xffn)
      .toString(16)
      .padStart(2, "0")
  ).join("");

  const bytes = crypto.getRandomValues(new Uint8Array(14));
  const rand = Array.from(bytes, (b) => ID_CHARS[b % 62]).join("");
  return `${prefix}_${timeHex}${rand}`;
}

// Inject OpenCode Zen client headers for opencode.ai; keep the legacy
// User-Agent for GitHub Copilot endpoints.
const originalFetch = globalThis.fetch;
globalThis.fetch = async function (input: RequestInfo | URL, init?: RequestInit) {
  const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;

  if (typeof url === "string" && url.includes("opencode.ai")) {
    init = init || {};
    const now = Date.now();
    const sessionId = generateId("ses", true, now - 3000);
    const requestId = generateId("msg", false, now);
    const headersToInject: Record<string, string> = {
      "User-Agent": USER_AGENT,
      "user-agent": USER_AGENT,
      "x-opencode-client": "cli",
      "x-opencode-project": "global",
      "x-opencode-session": sessionId,
      "x-opencode-request": requestId
    };
    if (!init.headers) {
      init.headers = headersToInject;
    } else if (init.headers instanceof Headers) {
      for (const [k, v] of Object.entries(headersToInject)) {
        if (!init.headers.has(k) || k.toLowerCase() === "user-agent") {
          init.headers.set(k, v);
        }
      }
    } else if (Array.isArray(init.headers)) {
      for (const [k, v] of Object.entries(headersToInject)) {
        init.headers.push([k, v]);
      }
    } else {
      Object.assign(init.headers, headersToInject);
    }
    return originalFetch(input, init);
  }

  if (
    typeof url === "string" &&
    (url.includes("githubcopilot.com") ||
      url.includes("copilot-api."))
  ) {
    if (init) {
      init.headers = init.headers || {};
      if (init.headers instanceof Headers) {
        init.headers.set("User-Agent", COPILOT_UA);
      } else if (Array.isArray(init.headers)) {
        init.headers.push(["User-Agent", COPILOT_UA]);
      } else {
        (init.headers as Record<string, string>)["User-Agent"] = COPILOT_UA;
      }
    }
  }

  return originalFetch(input, init);
};

export default function (pi: ExtensionAPI) {
  const opencodeProviders = ["oc", "opencode", "opencode-go", "opencode-zen"];
  for (const p of opencodeProviders) {
    pi.registerProvider(p, {
      headers: {
        "User-Agent": USER_AGENT,
        "x-opencode-client": "cli",
        "x-opencode-project": "global"
      }
    });
  }
  pi.registerProvider("github-copilot", {
    headers: {
      "User-Agent": COPILOT_UA
    }
  });
}
