import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";

// Resolve the locally installed opencode version for the spoofed User-Agent.
function opencodeVersion(): string {
  try {
    return execSync("opencode --version", { encoding: "utf8", timeout: 5000 }).trim();
  } catch {
    return "1.18.21"; // fallback if the binary is unavailable
  }
}
const UA = `opencode/latest/${opencodeVersion()}/cli`;

// Inject opencode User-Agent header for all outbound calls to opencode.ai and
// GitHub Copilot endpoints.
const originalFetch = globalThis.fetch;
globalThis.fetch = async function (input: RequestInfo | URL, init?: RequestInit) {
  const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
  if (
    typeof url === "string" &&
    (url.includes("opencode.ai") ||
      url.includes("githubcopilot.com") ||
      url.includes("copilot-api."))
  ) {
    if (init) {
      init.headers = init.headers || {};
      if (init.headers instanceof Headers) {
        init.headers.set("User-Agent", UA);
      } else if (Array.isArray(init.headers)) {
        init.headers.push(["User-Agent", UA]);
      } else {
        (init.headers as Record<string, string>)["User-Agent"] = UA;
      }
    }
  }
  return originalFetch(input, init);
};

export default function (pi: ExtensionAPI) {
  const providers = ["oc", "opencode", "opencode-go", "github-copilot"];
  for (const p of providers) {
    pi.registerProvider(p, {
      headers: {
        "User-Agent": UA
      }
    });
  }
}
