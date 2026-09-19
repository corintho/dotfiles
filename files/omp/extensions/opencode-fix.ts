import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const OPENCODE_VERSION = "2.0.9";
const USER_AGENT = `opencode/${OPENCODE_VERSION} ai-sdk/provider-utils/4.0.40 runtime/bun/1.3.14`;

// ---------------------------------------------------------------------------
// Stable session identity
//
// The OpenCode gateway routes and token-caches per x-opencode-session. Sending
// a fresh random session id on every request defeats caching and looks like an
// abusive client (HTTP 429), while sending a foreign id it cannot parse as a
// session gets rejected outright (HTTP 403). We therefore bind to pi's own
// conversation id (stable across turns, resume, compaction, and retries) and
// derive a valid ses_-prefixed, ULID-shaped id from it deterministically.
// Same conversation -> same session id, everywhere, every time.
// ---------------------------------------------------------------------------
let opencodeSessionId = "";

// Fallback id in case a request fires before the first session_start event
// (session_start always precedes any LLM call, so this is nearly never used).
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

// FNV-1a 64-bit string hash (deterministic).
function fnv1a(str: string): bigint {
  let h = 0xcbf29ce484222325n;
  const MASK = 0xffffffffffffffffn;
  for (let i = 0; i < str.length; i++) {
    h ^= BigInt(str.charCodeAt(i));
    h = (h * 0x100000001b3n) & MASK;
  }
  return h;
}

// splitmix64 PRNG seeded from a bigint.
function splitmix64(seed: bigint): () => bigint {
  let state = seed & 0xffffffffffffffffn;
  return () => {
    state = (state + 0x9e3779b97f4a7c15n) & 0xffffffffffffffffn;
    let z = state;
    z = ((z ^ (z >> 30n)) * 0xbf58476d1ce4e5b9n) & 0xffffffffffffffffn;
    z = ((z ^ (z >> 27n)) * 0x94d049bb133111ebn) & 0xffffffffffffffffn;
    return (z ^ (z >> 31n)) & 0xffffffffffffffffn;
  };
}

// Deterministic ses_-prefixed, ULID-shaped session id derived from a seed
// (pi's conversation id). Same seed -> same id, anywhere, anytime. The shape
// matches what the gateway accepts (ses_ + 12 hex + 14 chars).
function sessionIdFromSeed(seed: string): string {
  const rng = splitmix64(fnv1a(seed));
  const bytes: number[] = [];
  while (bytes.length < 20) {
    const v = rng();
    for (let shift = 56; shift >= 0; shift -= 8) {
      bytes.push(Number((v >> BigInt(shift)) & 0xffn));
    }
  }
  const timeHex = bytes
    .slice(0, 6)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  const rest = bytes.slice(6, 20).map((b) => ID_CHARS[b % 62]).join("");
  return `ses_${timeHex}${rest}`;
}

opencodeSessionId = sessionIdFromSeed(
  `${Date.now()}-${crypto.getRandomValues(new Uint8Array(8)).join("-")}`,
);

// ---------------------------------------------------------------------------
// Header injection
//
// Two layers:
//   1. pi.registerProvider(...) headers - always reach the request even if the
//      fetch patch below does not intercept the call (issue #4847 workaround).
//   2. globalThis.fetch patch - overrides the session id with the live,
//      per-conversation value when pi's HTTP goes through the global fetch.
// ---------------------------------------------------------------------------
const originalFetch = globalThis.fetch;
let patchedLog = false;

globalThis.fetch = async function (input: RequestInfo | URL, init?: RequestInit) {
  const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;

  if (typeof url === "string" && url.includes("opencode.ai")) {
    if (!patchedLog) {
      patchedLog = true;
      console.log(`[opencode-fix] intercepting opencode.ai request; session=${opencodeSessionId}`);
    }
    init = init || {};
    const headersToInject: Record<string, string> = {
      "User-Agent": USER_AGENT,
      "user-agent": USER_AGENT,
      "x-opencode-client": "cli",
      "x-opencode-project": "global",
      "x-opencode-session": opencodeSessionId,
      "x-opencode-request": generateId("msg", false, Date.now()),
    };

    // These are the headers we own; our dynamic values must always win.
    const alwaysOwn = new Set(["user-agent", "x-opencode-session", "x-opencode-request"]);

    if (!init.headers) {
      init.headers = headersToInject;
    } else if (init.headers instanceof Headers) {
      for (const [k, v] of Object.entries(headersToInject)) {
        if (!init.headers.has(k) || alwaysOwn.has(k.toLowerCase())) {
          init.headers.set(k, v);
        }
      }
    } else if (Array.isArray(init.headers)) {
      init.headers = init.headers.filter(([k]) => !alwaysOwn.has(k.toLowerCase()));
      const present = new Set(init.headers.map(([k]) => k.toLowerCase()));
      for (const [k, v] of Object.entries(headersToInject)) {
        if (!present.has(k.toLowerCase())) {
          init.headers.push([k, v]);
        }
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
        init.headers.set("User-Agent", USER_AGENT);
      } else if (Array.isArray(init.headers)) {
        init.headers.push(["User-Agent", USER_AGENT]);
      } else {
        (init.headers as Record<string, string>)["User-Agent"] = USER_AGENT;
      }
    }
  }

  return originalFetch(input, init);
};

export default function (pi: ExtensionAPI) {
  // Bind x-opencode-session to a deterministic ses_-shaped id derived from pi's
  // conversation id, so the gateway never sees a raw foreign id (which yields 403).
  pi.on("session_start", (_event, ctx) => {
    const sid = ctx.sessionManager.getSessionId();
    if (sid) {
      const next = sessionIdFromSeed(sid);
      if (next !== opencodeSessionId) {
        opencodeSessionId = next;
        console.log(`[opencode-fix] session bound ${opencodeSessionId} (seed=${sid})`);
      }
    }
  });

  // Diagnostic: watch for rate limiting / errors from the gateway.
  pi.on("after_provider_response", (event) => {
    if (event.status >= 400) {
      const retryAfter = event.headers?.["retry-after"];
      console.log(`[opencode-fix] provider response ${event.status}${retryAfter ? ` (retry-after: ${retryAfter})` : ""}`);
    }
  });

  const opencodeProviders = ["oc", "opencode", "opencode-go", "opencode-zen"];
  for (const p of opencodeProviders) {
    pi.registerProvider?.(p, {
      headers: {
        "User-Agent": USER_AGENT,
        "x-opencode-client": "cli",
        "x-opencode-project": "global",
        "x-opencode-session": opencodeSessionId,
      },
    });
  }
  pi.registerProvider?.("github-copilot", {
    headers: {
      "User-Agent": USER_AGENT,
    },
  });
}