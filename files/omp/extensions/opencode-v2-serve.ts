// SPDX markers omitted; reference notes only.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { AssistantMessageEventStream } from "@oh-my-pi/pi-ai/utils/event-stream";
import {
  type Api,
  type AssistantMessage,
  type Context,
  type ImageContent,
  type Message,
  type Model,
  type SimpleStreamOptions,
  type TextContent,
  type Tool,
  type ToolCall,
} from "@oh-my-pi/pi-ai";
import { spawn } from "node:child_process";
import type { ChildProcess } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { mkdir, mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { delimiter, join, resolve } from "node:path";
const PROVIDER_ID = "opencode-server-v2";
const API_ID = "opencode-server-v2-runner";
const VERSION: string = (() => {
  try {
    return (JSON.parse(readFileSync(new URL("../package.json", import.meta.url), "utf8")) as { version: string }).version;
  } catch {
    return "unknown";
  }
})();
const DEFAULT_CONTEXT_WINDOW = 128_000;
const DEFAULT_MAX_TOKENS = 16_384;
const DISCOVERY_TIMEOUT_MS = 8_000;
const SERVER_START_TIMEOUT_MS = 12_000;

const DEFAULT_FREE_MODELS = [
  "opencode/deepseek-v4-flash-free",
  "opencode/big-pickle",
  "opencode/mimo-v2.5-free",
];

const DISABLED_TOOLS: Record<string, false> = {
  bash: false, edit: false, read: false, glob: false, grep: false,
  list: false, task: false, webfetch: false, websearch: false, todowrite: false,
  // v2 exposes the shell tool under the name "shell" (not "bash"); leaving it
  // out here let the model route tool calls through the native channel, where
  // the service executes them server-side and the bridge never sees a marker.
  shell: false,
};

function opencodeBin(): string {
  const override = process.env.OPENCODE_OMP_BIN?.trim();
  if (override) return override;
  // Resolve against this process's cwd, not the child's: ensureServer() spawns the
  // server with cwd set to an isolated sandbox, so a relative PATH entry (`node_modules/.bin`
  // inside a devenv/direnv shell) would be resolved under that sandbox, miss, and silently
  // fall through to an unrelated `opencode` further down PATH.
  const names = process.platform === "win32" ? ["opencode.exe", "opencode.cmd", "opencode.bat"] : ["opencode"];
  for (const entry of (process.env.PATH ?? "").split(delimiter)) {
    const dir = entry ? resolve(entry) : process.cwd();
    for (const name of names) {
      const candidate = join(dir, name);
      if (existsSync(candidate)) return candidate;
    }
  }
  return "opencode";
}

function configuredModels(): string[] | undefined {
  const raw = process.env.OPENCODE_OMP_MODELS?.trim();
  return raw ? raw.split(",").map((m) => m.trim()).filter(Boolean) : undefined;
}

function modelDisplayName(model: string): string {
  const slash = model.indexOf("/");
  const id = slash >= 0 ? model.slice(slash + 1) : model;
  return id.replace(/-/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

function contextWindowFor(model: string): number {
  return model.includes("big-pickle") ? 200_000 : DEFAULT_CONTEXT_WINDOW;
}
function maxTokensFor(model: string): number {
  return model.includes("big-pickle") ? 32_768 : DEFAULT_MAX_TOKENS;
}

function runCapture(args: string[], input?: string, timeoutMs = DISCOVERY_TIMEOUT_MS): Promise<{ stdout: string; stderr: string; code: number | null }> {
  const child = spawn(opencodeBin(), args, { stdio: ["pipe", "pipe", "pipe"] });
  let stdout = "";
  let stderr = "";
  const p: Promise<{ stdout: string; stderr: string; code: number | null }> = new Promise((res) => {
    child.stdout!.on("data", (c) => (stdout += c));
    child.stderr!.on("data", (c) => (stderr += c));
    child.on("error", () => res({ stdout, stderr, code: null }));
    child.on("close", (code) => res({ stdout, stderr, code }));
  })
  if (input !== undefined) child.stdin!.write(input);
  return p;
}

async function discoverModels(): Promise<{ models: string[]; time: number; error?: string }> {
  if (configuredModels()) return { models: [...new Set(configuredModels())], time: Date.now(), error: undefined };
  try {
    const result = await runCapture(["models"]);
    if (result.code !== 0) throw new Error(result.stderr.trim() || `opencode models exited with code ${result.code}`);
    const discovered = result.stdout
      .split(/\r?\n/)
      .map((l) => l.trim())
      .filter((l) => l.startsWith("opencode/"))
      .filter((m) => /(^opencode\/.*-free$)|(^opencode\/big-pickle$)/.test(m));
    if (discovered.length === 0) {
      throw new Error("no free opencode models found in CLI output; falling back");
    }
    return { models: [...new Set(discovered)], time: Date.now(), error: undefined };
  } catch (error) {
    return { models: DEFAULT_FREE_MODELS, time: Date.now(), error: error instanceof Error ? error.message : String(error) };
  }
}

interface OcServer {
  url: string;
  proc: ChildProcess | null;
  password: string;
}

let currentServer: OcServer | undefined;

function b64auth(password: string): string {
    return `Basic ${Buffer.from(`opencode:${password}`).toString('base64')}`;
}




async function loadOrCreateServicePassword(configPath: string): Promise<string> {
  if (existsSync(configPath)) {
    const parsed = JSON.parse(readFileSync(configPath, "utf8")) as Record<string, unknown>;
    if (typeof parsed.password === "string") return parsed.password;
  }
  return process.env.OPENCODE_PASSWORD ?? process.env.OPENCODE_SERVER_PASSWORD ?? "opencode";
}
async function runningServiceUrl(): Promise<OcServer | undefined> {
  const baseDir = join(await homeDir(), ".config", "opencode");
  const configPath = join(baseDir, "service.json");
  const expectedPassword = await loadOrCreateServicePassword(configPath);
  for await (const port of candidatePorts()) {
    if (port) {
      try {
        const resp = await fetch(`http://127.0.0.1:${port}/api/event`, { headers: { Authorization: b64auth(expectedPassword) } });
        if (resp.ok) {
          currentServer = { url: `http://127.0.0.1:${port}`, proc: null, password: expectedPassword };
          return currentServer;
        }
      } catch {}
    }
  }
  return undefined;
}
async function* candidatePorts(): AsyncIterable<number | undefined> {
  const proc = spawn("ss", ["-tlnp"], { stdio: ["ignore", "pipe", "ignore"] });
  let out = "";
  proc.stdout!.on("data", (c) => (out += c));
  await new Promise<void>((res) => proc.on("exit", res));
  for (const line of out.split("\n")) {
    const m = line.match(/127\.0\.0\.1:(\d+)/);
    if (m) yield Number(m[1]);
  }
  yield undefined;
}

async function homeDir(): Promise<string> {
  return process.env.HOME ?? process.env.USERPROFILE ?? tmpdir();
}

async function ensureServer(): Promise<OcServer> {
  if (currentServer) return currentServer;
  if (process.env.OPENCODE_OMP_FORCE_SPAWN?.trim() !== "1") {
    const existing = await runningServiceUrl();
    if (existing) return existing;
  }

  const dir = await mkdtemp(join(tmpdir(), "opencode-v2-"));
  // Fully isolated instance: own XDG dirs so it never touches the user's
  // ~/.config/opencode, ~/.local/state/opencode or ~/.local/share/opencode.
  const spawnEnv: NodeJS.ProcessEnv = {
    ...process.env,
    OPENCODE_DISABLE_UPDATE_CHECK: "1",
    // Non-`--service` v2 instances never persist a password to service.json;
    // they print one per run. Fix it via env instead so we know it.
    OPENCODE_SERVER_PASSWORD: process.env.OPENCODE_SERVER_PASSWORD?.trim() || "opencode-v2-omp-spawned",
    XDG_CONFIG_HOME: join(dir, "config"),
    XDG_DATA_HOME: join(dir, "data"),
    XDG_CACHE_HOME: join(dir, "cache"),
    XDG_STATE_HOME: join(dir, "state"),
  };
  for (const sub of ["config", "data", "cache", "state"]) {
    await mkdir(join(dir, sub), { recursive: true });
  }
  const port = 49000 + Math.floor(Math.random() * 5000);
  const { promise, resolve: resolveUrl, reject: rejectUrl } = Promise.withResolvers<string>();
  let settled = false;
  const proc: ChildProcess = spawn(opencodeBin(), ["serve", "--hostname=127.0.0.1", `--port=${port}`], {
    cwd: dir,
    env: spawnEnv,
    stdio: ["ignore", "pipe", "pipe"],
  });
  let stderrTail = "";
  proc.stderr!.on("data", (c) => {
    stderrTail = (stderrTail + c.toString()).slice(-2000);
  });
  const timer = setTimeout(() => {
    if (settled) return;
    settled = true;
    proc.kill("SIGTERM");
    rejectUrl(new Error(`opencode v2 serve start timeout after ${SERVER_START_TIMEOUT_MS}ms${stderrTail ? `; stderr: ${stderrTail}` : ""}`));
  }, SERVER_START_TIMEOUT_MS);
  proc.stdout!.on("data", (c) => {
    // v2 prints: "server listening on http://127.0.0.1:PORT"
    const m = c.toString().match(/listening on (https?:\/\/[^\s]+)/);
    if (m && !settled) { settled = true; clearTimeout(timer); resolveUrl(m[1]); }
  });
  proc.on("error", (err) => {
    if (settled) return;
    settled = true;
    clearTimeout(timer);
    rejectUrl(err);
  });
  proc.on("exit", (code) => {
    currentServer = undefined;
    if (settled) return;
    settled = true;
    clearTimeout(timer);
    rejectUrl(new Error(`opencode v2 serve exited early with code ${code}${stderrTail ? `; stderr: ${stderrTail}` : ""}`));
  });
  const url = await promise;
  currentServer = { url, proc, password: spawnEnv.OPENCODE_SERVER_PASSWORD as string };
  return currentServer;
}

function shutdownSpawnedServer(): void {
  const server = currentServer;
  currentServer = undefined;
  if (server?.proc) {
    server.proc.removeAllListeners("exit");
    server.proc.kill("SIGTERM");
  }
}
function contentToText(content: string | (TextContent | ImageContent)[]): string {
  if (typeof content === "string") return content;
  return content.filter((i): i is TextContent => "text" in i).map((i) => i.text).join("\n");
}

function parseToolCalls(text: string): Array<{ name: string; arguments: Record<string, unknown> }> {
  const trimmed = text.trim();
  const tagRegex = /<omp_tool_call>([\s\S]*?)<\/omp_tool_call>/g;
  const matches = [...trimmed.matchAll(tagRegex)];
  if (matches.length) return matches.flatMap((m) => parseToolCallJson(m[1] ?? ""));
  // Fenced/wrapped whole-response marker: strip code fences, then the tag
  // itself, so {"tool":"bash",...} becomes the fallback-parse candidate.
  const unwrapped = trimmed
    .replace(/```[a-zA-Z]*\s*/g, "")
    .replace(/<\/?omp_tool_call>/g, "")
    .trim();
  return parseToolCallJson(unwrapped);
}

function parseToolCallJson(raw: string): Array<{ name: string; arguments: Record<string, unknown> }> {
  let value: unknown;
  try { value = JSON.parse(raw.trim()); } catch { return []; }
  const candidates: unknown[] = Array.isArray(value)
    ? value
    : value !== null && typeof value === "object" && "tool_calls" in value && Array.isArray(value.tool_calls)
      ? value.tool_calls
      : [value];
  const calls: Array<{ name: string; arguments: Record<string, unknown> }> = [];
  for (const candidate of candidates) {
    if (candidate === null || typeof candidate !== "object") continue;
    let name: string | undefined;
    if ("name" in candidate && typeof candidate.name === "string") name = candidate.name;
    else if ("tool" in candidate && typeof candidate.tool === "string") name = candidate.tool;
    if (!name) continue;
    let args: unknown = {};
    if ("arguments" in candidate) args = candidate.arguments;
    else if ("args" in candidate) args = candidate.args;
    else if ("input" in candidate) args = candidate.input;
    if (typeof args !== "object" || args === null || Array.isArray(args)) continue;
    calls.push({ name, arguments: args as Record<string, unknown> });
  }
  return calls;
}

function parseSseBlocks(raw: string): Array<{ type: string; dataData?: Record<string, unknown> }> {
  const events: Array<{ type: string; dataData?: Record<string, unknown> }> = [];
  for (const block of raw.split(/\n\n/)) {
    const dataLine = block.split("\n").find((l) => l.startsWith("data:"));
    if (!dataLine) continue;
    try {
      const parsed = JSON.parse(dataLine.slice(5).trim()) as { type?: unknown; data?: Record<string, unknown> };
      if (typeof parsed.type === "string") events.push({ type: parsed.type, dataData: parsed.data });
    } catch {
    }
  }
  return events;
}

function serializeMessage(message: Message): string {
  if (message.role === "user") {
    return "USER:\n" + contentToText(message.content as (TextContent | ImageContent)[] | string);
  }
  if (message.role === "toolResult") {
    return [
      `OMP TOOL RESULT (${message.toolName}, id=${message.toolCallId}, isError=${message.isError}):`,
      contentToText(message.content as (TextContent | ImageContent)[] | string),
    ].join("\n");
  }
  const rawContent = message.content;
  if (typeof rawContent === "string") return "ASSISTANT:\n" + rawContent;
  const parts = (rawContent as unknown[]).map((part: unknown) => {
    if (part === null || typeof part !== "object") return String(part);
    if ("type" in part) {
      if (part.type === "text" && "text" in part && typeof part.text === "string") return part.text;
      if (part.type === "thinking" && "thinking" in part && typeof part.thinking === "string")
        return `<thinking>${part.thinking}</thinking>`;
      if (part.type === "toolCall" && "name" in part && "arguments" in part)
        return `<omp_tool_call>${JSON.stringify({ name: part.name, arguments: part.arguments })}</omp_tool_call>`;
    }
    return JSON.stringify(part);
  });
  return "ASSISTANT:\n" + parts.join("\n");
}

function buildPrompt(context: Context): string {
  const sections: string[] = [];
  const system = context.systemPrompt ?? "";
  if (system) sections.push(system);
  sections.push("You are the OpenCode side of an OMP coding agent bridge. OpenCode tools are denied; OMP tool calls must be emitted as `<omp_tool_call>...</omp_tool_call>` markers. After OMP returns tool results, use them to answer or emit another tool call. When a tool is needed, you MUST output the literal marker `<omp_tool_call>{\"name\":\"bash\",\"arguments\":{\"command\":\"...\"}}</omp_tool_call>` as part of your reply text. NEVER merely announce a tool call without emitting the marker; NEVER attempt any other tool-call syntax. Do not wrap the marker in code fences.");
  if (context.truncatedHistory) sections.push("## Conversation context:\n" + context.truncatedHistory);
  sections.push("## Tools:\n" + (context.tools ?? []).length + " tool(s): " + ((context.tools ?? []).map((t) => t.name).join(", ") || "none") + " (commands not available)");
  if (context.fileContext) sections.push("## File context:\n" + JSON.stringify(context.fileContext, null, 2));
  sections.push("## Conversation transcript:");
  for (const m of (context.messages ?? [])) sections.push(serializeMessage(m));
  sections.push("Now produce the next assistant message for OMP.");
  return sections.join("\n\n---\n\n");
}

function parseAssistantContent(text: string, output: AssistantMessage, stream: AssistantMessageEventStream, lastIndex: number): void {
  let idx = lastIndex;
  const toolCalls = parseToolCalls(text);
  if (toolCalls.length) {
    stream.push({ type: "text_end", contentIndex: idx, content: text, partial: output });
    output.stopReason = "toolUse";
    for (const call of toolCalls) {
      const toolCall: ToolCall = {
        type: "toolCall",
        id: `opencode_omp_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
        name: call.name,
        arguments: call.arguments,
      };
      const contentIndex = (output.content as unknown[]).length;
      (output.content as unknown[]).push(toolCall);
      stream.push({ type: "toolcall_start", contentIndex, partial: output });
      stream.push({ type: "toolcall_delta", contentIndex, delta: JSON.stringify(toolCall.arguments), partial: output });
      stream.push({ type: "toolcall_end", contentIndex, toolCall, partial: output });
    }
    stream.push({ type: "done", reason: "toolUse", message: output });
    stream.end();
  } else {
    stream.push({ type: "text_end", contentIndex: idx, content: text, partial: output });
    stream.push({ type: "done", reason: "stop", message: output });
    stream.end();
  }
}

function streamOpenCode(
  _model: Model<Api>,
  context: Context,
  options?: SimpleStreamOptions,
): AssistantMessageEventStream {
  const stream = new AssistantMessageEventStream();

  (async () => {
    const output: AssistantMessage = {
      role: "assistant",
      content: [],
      api: _model.api,
      provider: _model.provider,
      model: _model.id,
      usage: emptyUsage(),
      stopReason: "stop",
      timestamp: Date.now(),
    };

    const server = await ensureServer();
    const baseUrl = server.url;
    const auth = b64auth(server.password);
    const slashIdx = _model.id.indexOf("/");
    const providerID = slashIdx >= 0 ? _model.id.slice(0, slashIdx) : _model.id;
    const modelID = slashIdx >= 0 ? _model.id.slice(slashIdx + 1) : _model.id;

    const hasTool = (context.tools?.length ?? 0) > 0;
    const st = { textMode: "gating", gateBuffer: "", textContentIndex: -1 };
    let reasoningContentIndex = -1;
    let accumulatedText = "";
    let sessionId: string | undefined;
    let sseReader: ReadableStreamDefaultReader<Uint8Array> | undefined;

    const assistantMsgIds = new Set<string>();
    const reasoningMsgIds = new Set<string>();
    const pendingText = new Map<string, string[]>();
    const pendingReasoning = new Map<string, string[]>();
    const reasoningTextById = new Map<string, string>();

    const handleTextDelta = (delta: string): void => {
      accumulatedText += delta;
      if (st.textMode === "buffered") return;
      if (st.textMode === "streaming") {
        const block = (output.content as unknown[])[st.textContentIndex] as { text: string };
        block.text += delta;
        stream.push({ type: "text_delta", contentIndex: st.textContentIndex, delta, partial: output });
        return;
      }
      st.gateBuffer += delta;
      const firstNonWS = st.gateBuffer.trimStart()[0];
      if (firstNonWS === undefined) return;
      if (firstNonWS === "<" || firstNonWS === "{" || firstNonWS === "[") {
        st.textMode = "buffered";
        return;
      }
      st.textMode = "streaming";
      st.textContentIndex = (output.content as unknown[]).length;
      (output.content as unknown[]).push({ type: "text", text: "" });
      stream.push({ type: "text_start", contentIndex: st.textContentIndex, partial: output });
      (output.content as unknown[])[st.textContentIndex] = { type: "text", text: st.gateBuffer };
      stream.push({ type: "text_delta", contentIndex: st.textContentIndex, delta: st.gateBuffer, partial: output });
      st.gateBuffer = "";
    };

    const dispatchDelta = (msgId: string, delta: string): void => {
      if (!delta) return;
      if (assistantMsgIds.has(msgId)) handleTextDelta(delta);
      else {
        const buf = pendingText.get(msgId) ?? [];
        buf.push(delta);
        pendingText.set(msgId, buf);
      }
    };

    const flushPending = (msgId: string): void => {
      const pending = pendingText.get(msgId);
      if (pending) {
        pendingText.delete(msgId);
        for (const delta of pending) handleTextDelta(delta);
      }
    };

    const handleReasoningDelta = (delta: string): void => {
      if (!delta) return;
      if (reasoningContentIndex === -1) {
        reasoningContentIndex = (output.content as unknown[]).length;
        (output.content as unknown[]).push({ type: "thinking", thinking: "" });
        stream.push({ type: "thinking_start", contentIndex: reasoningContentIndex, partial: output });
      }
      const block = (output.content as unknown[])[reasoningContentIndex] as { thinking: string };
      block.thinking += delta;
      stream.push({ type: "thinking_delta", contentIndex: reasoningContentIndex, delta, partial: output });
    };

    const dispatchReasoning = (msgId: string, delta: string): void => {
      if (!delta) return;
      reasoningTextById.set(msgId, (reasoningTextById.get(msgId) ?? "") + delta);
      if (reasoningMsgIds.has(msgId)) handleReasoningDelta(delta);
      else {
        const buf = pendingReasoning.get(msgId) ?? [];
        buf.push(delta);
        pendingReasoning.set(msgId, buf);
      }
    };

    const flushPendingReasoning = (msgId: string): void => {
      const pending = pendingReasoning.get(msgId);
      if (pending) {
        pendingReasoning.delete(msgId);
        for (const delta of pending) handleReasoningDelta(delta);
      }
    };

    const cleanup = async () => {
      sseReader?.cancel().catch(() => undefined);
      if (sessionId) {
        await fetch(`${baseUrl}/api/session/${sessionId}`, { method: "DELETE", headers: { Authorization: auth } }).catch(() => undefined);
        sessionId = undefined;
      }
    };
    try {
      stream.push({ type: "start", partial: output });

      const sessResp = await fetch(`${baseUrl}/api/session`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: auth },
        body: JSON.stringify({}),
      });
      if (!sessResp.ok) throw new Error(`session create failed: ${sessResp.status}`);
      const sess = await sessResp.json() as { data: { id: string } };
      sessionId = sess.data.id;
      const modelResp = await fetch(`${baseUrl}/api/session/${sessionId}/model`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: auth },
        body: JSON.stringify({ model: { id: modelID, providerID } }),
      });
      if (!modelResp.ok) throw new Error(`model select failed: ${modelResp.status}`);

      const prompt = buildPrompt(context);

      const sseAbort = new AbortController();
      const onAbort = () => sseAbort.abort();
      options?.signal?.addEventListener("abort", onAbort, { once: true });

      const evtResp = await fetch(`${baseUrl}/api/event`, { signal: sseAbort.signal, headers: { Authorization: auth } });
      if (!evtResp.ok) throw new Error(`event stream failed: ${evtResp.status}`);
      sseReader = evtResp.body!.getReader();
      const promptResp = await fetch(`${baseUrl}/api/session/${sessionId}/prompt`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: auth },
        body: JSON.stringify({ text: prompt, tools: DISABLED_TOOLS }),
      });
      if (!promptResp.ok) {
        throw new Error(`prompt rejected: ${promptResp.status} ${(await promptResp.text()).slice(0, 300)}`);
      }

      const dec = new TextDecoder();
      let sseRemainder = "";
      let done = false;

      while (!done) {
        if (options?.signal?.aborted) throw new Error("Request was aborted");
        const { done: rdDone, value } = await sseReader.read();
        if (rdDone) break;
        sseRemainder += dec.decode(value, { stream: true });
        const blockBoundary = sseRemainder.lastIndexOf("\n\n");
        if (blockBoundary < 0) continue;
        const toProcess = sseRemainder.slice(0, blockBoundary + 2);
        sseRemainder = sseRemainder.slice(blockBoundary + 2);
        for (const ev of parseSseBlocks(toProcess)) {
          if (ev.type === "server.connected") continue;
          if (ev.type === "session.reasoning.started") {
            reasoningMsgIds.add((ev.dataData?.assistantMessageID as string) ?? "");
            continue;
          }
          if (ev.type === "session.reasoning.delta") {
            dispatchReasoning(
              (ev.dataData?.assistantMessageID as string) ?? "",
              (ev.dataData?.delta as string) ?? "",
            );
            continue;
          }
          if (ev.type === "session.reasoning.ended") {
            // The service sends the full reasoning text here; fall back to it
            // only when no delta for this message reached us (short reasoning
            // can arrive as started/ended alone).
            const msgId = (ev.dataData?.assistantMessageID as string) ?? "";
            const fullText = (ev.dataData?.text as string | undefined) ?? "";
            if (reasoningMsgIds.has(msgId) && !reasoningTextById.has(msgId)) dispatchReasoning(msgId, fullText);
            continue;
          }
          if (ev.type === "session.text.started") {
            assistantMsgIds.add((ev.dataData?.assistantMessageID as string) ?? "");
            continue;
          }
          if (ev.type === "session.text.delta") {
            const delta = ev.dataData?.delta;
            const msgId = (ev.dataData?.assistantMessageID as string) ?? "";
            if (!delta) continue;
            dispatchDelta(msgId, delta as string);
            continue;
          }
          if (ev.type === "session.step.started" || ev.type === "session.step.streamed") continue;
          if (ev.type === "session.execution.succeeded") {
            done = true;
            await fetch(`${baseUrl}/api/session/${sessionId}`, { method: "DELETE", headers: { Authorization: auth } }).catch(() => undefined);
            sessionId = undefined;
            break;
          }
        }
      }
      options?.signal?.removeEventListener("abort", onAbort);
      sseAbort.abort();

      if (options?.signal?.aborted) throw new Error("Request was aborted");

      // Flush reasoning deltas that arrived before their session.reasoning.started
      for (const msgId of reasoningMsgIds) flushPendingReasoning(msgId);
      if (reasoningContentIndex !== -1) {
        const block = (output.content as unknown[])[reasoningContentIndex] as { thinking: string };
        stream.push({ type: "thinking_end", contentIndex: reasoningContentIndex, content: block.thinking, partial: output });
      }
      // Flush any buffered deltas that arrived before their session.text.started
      for (const msgId of assistantMsgIds) flushPending(msgId);
      parseAssistantContent(accumulatedText, output, stream, st.textContentIndex);
    } catch (error) {
      output.stopReason = options?.signal?.aborted ? "aborted" : "error";
      output.errorMessage = error instanceof Error ? error.message : String(error);
      stream.push({ type: "error", reason: output.stopReason, error: output });
      stream.end();
    } finally {
      await cleanup();
    }
  })();

  return stream;
}

function providerModels(models: string[]) {
  return models.map((model) => ({
    id: model,
    name: `${modelDisplayName(model)} (OpenCode v2 service)`,
    // The v2 service streams model reasoning as `session.reasoning.started/delta/ended`
    // events (verified against a live /api/event capture; opencode/big-pickle declares
    // `compatibility.reasoningField: "reasoning_content"` in /api/model). streamOpenCode()
    // surfaces those as `thinking` blocks, so models are advertised as reasoning-capable.
    // A model that streams no reasoning events emits no thinking block.
    reasoning: true,
    input: ["text"] as const,
    contextWindow: contextWindowFor(model),
    maxTokens: maxTokensFor(model),
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
  }));
}

/**
 * Zeroed `Usage` for a bridged turn.
 *
 * `Usage.cost` and `Usage.totalTokens` are REQUIRED (see @oh-my-pi/pi-catalog
 * `Usage`): omp's session bookkeeping does `usage.cost.total` unguarded
 * (session-stats.ts `addUsage`) and `getSessionStats()` runs inside the
 * `agent_end` branch of the session's agent listener, before it re-emits
 * `agent_end` to the UI. A message whose usage omits `cost` therefore throws
 * there, the terminal `agent_end` never reaches the TUI, and the interactive
 * "Working…" loader + turn timer never stop (the frame stays frozen until the
 * next keypress repaint). Always emit the full shape, zeros included.
 */
function emptyUsage(): AssistantMessage["usage"] {
  return {
    input: 0,
    output: 0,
    cacheRead: 0,
    cacheWrite: 0,
    totalTokens: 0,
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
  };
}

export default async function openCodeV2ServeExtension(pi: ExtensionAPI) {
  const { models, time } = await discoverModels();

  pi.registerProvider(PROVIDER_ID, {
    baseUrl: "cli:opencode",
    api: API_ID,
    apiKey: "opencode-no-api-key",
    models: providerModels(models),
    streamSimple: streamOpenCode,
  });

  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify(`opencode-v2-serve: registered ${models.length} model(s) via OpenCode v2 service.`, "info");
  });

  pi.on("session_shutdown", async () => {
    shutdownSpawnedServer();
  });

  pi.registerCommand("opencode-v2-serve", {
    description: "OpenCode v2 service bridge status and setup help",
    handler: async (args, ctx) => {
      const sub = args.trim().split(/\s+/).filter(Boolean)[0] ?? "status";
      if (sub === "status") {
        ctx.ui.notify([
          `opencode-v2-serve version: ${VERSION}`,
          `Provider: ${PROVIDER_ID}`,
          `OpenCode binary: ${opencodeBin()}`,
          `OpenCode installed: ${opencodeBin() === "opencode" ? "no (not found on PATH)" : "yes"}`,
          `Registered models: ${models.length}`,
          "",
          ...models.map((m) => `  - ${PROVIDER_ID}/${m}`),
          "",
          "Pick a model via /model and use ${PROVIDER_ID} (e.g. opencode/big-pickle).",
          "OpenCode tools are disabled; OMP tool use is bridged with prompt-level markers.",
          "Run /opencode-v2-serve update to refresh the model list from opencode."
        ].join("\n"), "info");
        return;
      }
      if (sub === "update") {
        const prev = models;
        const next = await discoverModels();
        pi.registerProvider(PROVIDER_ID, {
          baseUrl: "cli:opencode",
          api: API_ID,
          apiKey: "opencode-no-api-key",
          models: providerModels(next.models),
          streamSimple: streamOpenCode,
        });
        const added = next.models.filter((m) => !prev.includes(m));
        ctx.ui.notify([
          `opencode-v2-serve: refreshed ${next.models.length} model(s).` + (added.length ? ` ${added.length} new: ${added.slice(0, 5).join(", ")}${added.length > 5 ? ", ..." : ""}` : ""),
        ].join(""), "info");
        return;
      }
      ctx.ui.notify("Usage: /opencode-v2-serve [status|update|help]", "info");
    },
  });
}
