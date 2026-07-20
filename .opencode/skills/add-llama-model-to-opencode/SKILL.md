# add-llama-model-to-opencode

Downloads a GGUF model from HuggingFace, configures it for llama.cpp with intelligent flag inference, and adds it to both llama-swap and OpenCode settings.

## Activation

Trigger with: `/add-llama-model`, `add model`, `download and add llama model`, etc.

## Workflow

### Step 1 — Identify the model

User provides one of:
- Full HF URL: `https://huggingface.co/unsloth/Qwen3-14B-GGUF`
- Repo ID: `unsloth/Qwen3-14B-GGUF`
- Freeform name: `qwen3 14b gguf`

If freeform:
1. Run: `hf models list --search <name> --filter gguf --limit 10`
2. Present results with model IDs, download counts, and brief descriptions
3. Ask user to select or refine the search

Validate the selected repo:
- Run: `hf models info <repo_id>`
- Confirm it has `.gguf` files in the siblings list
- Extract `gguf.chat_template` and `gguf.architecture` for later use

### Step 2 — Select quantization file

From the siblings list, filter `.gguf` files:
- Exclude: `.BF16.gguf` (too large ~30GB), `UD-IQ1_*.gguf`, `UD-IQ2_*.gguf` (too aggressive)
- Extract file sizes (available from HF page or calculate from model card)
- **Score by size targeting 8–15GB range** (optimal for M2 Pro 32GB):
  - `UD-Q4_K_XL` (~9–12GB) = best choice
  - `Q4_K_M` (~9–10GB) = good fallback
  - `Q3_K_M` (~6–8GB) = acceptable if smaller preferred
  - `Q5_K_M` (~12–13GB) = larger, more accurate

Multimodal detection:
- Check if any sibling filename contains `mmproj` (e.g., `mmproj-gemma-4-E4B-it-Q8_0.gguf`)
- If found, also select the matching mmproj file for download

Present recommendation:
```
Recommended quant: Qwen3-14B-UD-Q4_K_XL.gguf (~9.2 GB)
Multimodal: No
[Confirm] [Choose different quant]
```

### Step 3 — Infer llama-server flags

Parse `gguf.chat_template` from Step 1's `hf models info` JSON response:

**Tool calling**:
- If template contains `<tool_call>` → `tools: true`
- Add `--jinja` flag for chat template processing
- Default: `tools: false`

**Reasoning**:
- If template contains `<think>` or `reasoning_content` → `reasoning: true`
- Default: `reasoning: false`

**Multimodal**:
- If mmproj file exists (from Step 2) → add `--mmproj <path>` to cmd
- Skip `-fa on` for multimodal (not always supported); use `-fa off` if needed
- Model family heuristics: Gemma → multimodal, Llama3.2-Vision → multimodal

**Base flags** (always applied):
- `-ngl 99` (offload all layers to GPU)
- `-c 0` (no context size limit in llama-swap config)

**If chat_template is ambiguous or missing**:
- Fetch the HF model page with WebFetch
- Search README for llama.cpp usage examples or mentions of `--jinja`, `--flash-attn`, etc.
- Ask user to confirm inferred flags before proceeding

Present flag summary:
```
Inferred configuration:
  Tools: true (detected <tool_call> in chat template)
  Reasoning: false
  Multimodal: no
  Flags: --jinja -ngl 99 -c 0 -fa on

[Confirm] [Edit flags] [Skip and ask me]
```

### Step 4 — Download

**Important:** Downloads can take a very long time (hours for large models). Use background process to avoid shell timeout.

Determine the snapshot hash **before downloading** (from `hf models info` SHA field in Step 1), so config edits can be prepared in parallel.

Start downloads in background with `nohup`:

```bash
nohup hf download <repo_id> <quant_filename> > /tmp/hf_download.log 2>&1 &
nohup hf download <repo_id> <mmproj_filename> > /tmp/hf_mmproj.log 2>&1 &  # if multimodal
```

`hf download` automatically saves to `~/.cache/huggingface/hub/` in the standard layout:
```
~/.cache/huggingface/hub/models--<org>--<repo>/snapshots/<hash>/<filename>
```

The snapshot path is predictable from the SHA, so **proceed with config edits while download is in progress**.

**Before applying config changes**, verify downloads completed:

```bash
# Poll for blob file (actual data stored as symlink in hub cache)
find ~/.cache/huggingface/hub/models--<org>--<repo>/blobs -type f -size +100M

# Confirm blob is the expected size (check hf models info for GGUF total size)
ls -lh ~/.cache/huggingface/hub/models--<org>--<repo>/blobs/<hash>
```

Once confirmed, the snapshot path is ready:
```
/Users/<username>/.cache/huggingface/hub/models--<org>--<repo>/snapshots/<hash>/<filename>
```

### Step 5 — Update `lcars.models`

**Important:** Models are now declared in a single location per platform, which drives both **llama-swap** and **opencode** automatically.

Determine which platform file to edit:
- **macOS (Darwin)**: `nix/darwin/home.nix`
- **NixOS (Linux)**: `nix/users/corintho/home.nix`

Locate the `lcars.models` attribute set and add a new entry with the captured paths from Step 4:

```nix
"unsloth/Qwen3-14B-GGUF:UD-Q4_K_XL" = {
  modelPath = "/Users/<username>/.cache/huggingface/hub/models--unsloth--Qwen3-14B-GGUF/snapshots/<hash>/Qwen3-14B-UD-Q4_K_XL.gguf";
  # mmprojPath is optional, only if multimodal
  mmprojPath = "/Users/<username>/.cache/huggingface/hub/.../mmproj-...gguf";
  # extraArgs: model-specific flags (--jinja, -fa on)
  extraArgs = [ "--jinja" "-fa" "on" ];
  name = "Qwen3 14B UD Q4_K_XL";
  tools = true;
  reasoning = false;
};
```

**Field reference:**
| Field | Required | Description |
|-------|----------|-------------|
| `modelPath` | yes | Full path to the GGUF file |
| `mmprojPath` | no | Multimodal projection file path |
| `extraArgs` | no | Model-specific llama-server flags |
| `name` | yes | Human-readable label for opencode |
| `tools` | no (default: true) | Tool-calling capability |
| `reasoning` | no (default: false) | Reasoning capability |

The `-ngl 99 -c 0` base flags are added automatically by the module — no need to specify them.

Validate with `just check` before proceeding to Step 6.

### Step 6 — No manual opencode edit needed

The `llama.cpp` provider models in opencode are **auto-generated** from `lcars.models`. No separate edit is required — just adding the model entry in Step 5 is sufficient.

### Step 7 — Validate

Run: `just check`

Confirm Nix syntax is valid and no errors.

### Step 8 — Report and remind to deploy

Show user:
- Model ID and quant selected
- File size and snapshot path (first 16 chars of hash)
- Inferred flags used in config
- Changes made to both `llama-cpp.nix` and `opencode.nix`
- Validation passed ✅

Tell user to run:
```bash
just deploy
```

Configuration will be activated on next model request to llama-swap.

---

## Implementation Notes

### Idempotency

- Check if model ID already exists in `lcars.models` (in the platform's `home.nix`)
- If found, offer to update (re-download with new quant) or skip
- Prevent duplicate entries

### hf CLI commands used

- `hf models list --search <query> --filter gguf --limit 10` — search
- `hf models info <repo_id>` — detailed model metadata (JSON)
- `hf download <repo_id> <filename>` — download with automatic cache directory

### Path handling

- Use captured absolute paths directly from `hf download` stdout
- No manual snapshot hash reconstruction needed
- Paths are stable across re-runs

### YAML format

- Always use inline `cmd: "..."` format, never `cmd: >` (folded scalars cause indentation bugs)
- Escape `$` variables as `''${VAR}` in Nix multiline strings

### Multimodal files

- Common naming: `mmproj-<model>-<quant>.gguf`, `proj-<model>.gguf`
- Download alongside the main model
- Always add `--mmproj` flag if present

### Flag inference fallback

If `gguf.chat_template` is missing or insufficient:
1. Use WebFetch to fetch the HF model page
2. Search README for llama.cpp examples
3. Search for mentions of `--jinja`, `--flash-attn`, multimodal support
4. Ask user to confirm or override

---

## Example Output

```
🔍 Searching for "qwen3 14b gguf"...

Found 5 models:
  1. unsloth/Qwen3-14B-GGUF (32.9k downloads) ← RECOMMENDED
  2. Qwen/Qwen3-14B (15.2k downloads)
  3. bartowski/Qwen3-14B-GGUF (8.1k downloads)

Select: 1

📦 Available quantizations:
  • Qwen3-14B-UD-Q4_K_XL.gguf    9.16 GB  ← RECOMMENDED
  • Qwen3-14B-Q4_K_M.gguf         9.00 GB
  • Qwen3-14B-Q3_K_M.gguf         7.32 GB

Select: 1 (Qwen3-14B-UD-Q4_K_XL.gguf)

🔧 Inferred configuration:
  Tools: true (detected <tool_call> in chat template)
  Reasoning: false
  Multimodal: no
  Flags: --jinja -ngl 99 -c 0 -fa on

Confirmed? (y/n) y

⬇️  Downloading Qwen3-14B-UD-Q4_K_XL.gguf (9.16 GB)...
   [████████████████████████] 100%

✅ Downloaded to: /Users/zg47ma/.cache/huggingface/hub/models--unsloth--Qwen3-14B-GGUF/snapshots/a04a82c4.../Qwen3-14B-UD-Q4_K_XL.gguf

📝 Updated lcars.models in home.nix:
   + "unsloth/Qwen3-14B-GGUF:UD-Q4_K_XL" = {
       modelPath = "...";
       extraArgs = [ "--jinja" "-fa" "on" ];
       name = "Qwen3 14B UD Q4_K_XL";
       tools = true;
       reasoning = false;
     };
   (llama-swap + opencode updated automatically)

✅ Validation passed (just check)

Next: run `just deploy` to activate the configuration.
```
