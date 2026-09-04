# add-llama-model-to-opencode

Downloads a GGUF model from HuggingFace, configures it for llama.cpp with intelligent flag inference, and adds it to both llama-swap and OpenCode settings.

## Hardware Context

This system hardware affects model and quantization recommendations:

| Component | Spec |
|---|---|
| GPU | NVIDIA GeForce RTX 5060 Ti (16 GB VRAM) + NVIDIA GeForce RTX 2060 SUPER (8 GB VRAM) |
| RAM | 62 GB |
| CPU | Intel i7-9700KF |

**IMPORTANT**: Do NOT hardcode hardware assumptions. Before evaluating whether a model fits, query the actual hardware:

```bash
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
```

Use the reported VRAM values for all budget calculations. The system has two GPUs — models can be split across both using `tensorSplit` in the model config. If a model fits entirely on the larger GPU alone, `tensorSplit` is still valid for load balancing but not strictly required.

**VRAM calculation methodology** (source: [bmdpat.com/blog/llama-cpp-n-gpu-layers-explained-2026](https://bmdpat.com/blog/llama-cpp-n-gpu-layers-explained-2026)):
- Get GGUF file size from HF file listing
- Get layer count from model card (e.g., `config.json` `num_hidden_layers`, or `hf models info` metadata)
- **Per-layer VRAM = GGUF_file_size / layer_count**
- **Max GPU layers = (usable_VRAM - KV_cache_headroom) / per_layer_VRAM**
- For single-GPU fit: compare total weight size against the target GPU's VRAM
- For multi-GPU: use `tensorSplit` to distribute weights across GPUs; KV cache budget is the total VRAM minus total weights across all GPUs
- Always specify `-ngl` in `extraArgs` per model (not a global default)
- `-ngl -1` offloads all layers (same as 999) — use only when model fits entirely in VRAM with headroom
- `-ngl 0` = CPU-only (slow on this system)

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
- **Record the GGUF file size** (shown in HF file listing) — needed later for `-ngl` calculation
- **Consider VRAM budget on the target GPU (query with `nvidia-smi` before recommending):**
  - **7B models at Q4_K_M** (~5-6 GB) = fits entirely on GPU → `-ngl -1`
  - **14B+ models** (partial offload required):
    - Smaller file size = more layers fit on GPU
    - The exact `-ngl` value will be calculated in Step 3 after layer count is known
  - **Flag the VRAM constraint when recommending 14B+ models**: tell user they need `-ngl` in `extraArgs`

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

**Base flags** (added automatically by the module — do NOT include in `extraArgs`):
- `-c 0` (no context size limit in llama-swap config)

**Required per-model flag** (always add to `extraArgs`): `-ngl <N>`

Calculate using the formula from the article:

1. **Look up layer count** — check the base model card on HF or run `hf models info <base_model>` for `num_hidden_layers` in `config.json`. Common values: 7B = 32, 14B = 40, Gemma 4 E4B = 42, 30B MoE = 48, 70B = 80.
2. **Per-layer VRAM** = GGUF_file_size_GB / layer_count
3. **Max GPU layers** = 5.0 GB / per_layer_VRAM (rounded down)
4. Set `-ngl` to that value. If the model fits entirely in VRAM (file size < ~5 GB after overhead), use `-ngl -1`.

Example: 9.16 GB file, 40 layers → 229 MB/layer → 5.0 GB / 0.229 GB = 21.8 → **`-ngl 20`**

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
  Flags (add to extraArgs): --jinja -fa on

[Confirm] [Edit flags] [Skip and ask me]
```

**Reminder:** `-c 0` is added automatically by the module. `-ngl` must be specified in `extraArgs` per model — calculate using the formula above and present the value to the user for confirmation.

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
  # extraArgs: model-specific flags including -ngl
  # -ngl calculated: file_size / layers = per_layer → weight_budget / per_layer = max_layers
  extraArgs = [ "-ngl" "20" "--jinja" "-fa" "on" ];
  name = "Qwen3 14B UD Q4_K_XL";
  tools = true;
  reasoning = false;
};
```

**ALWAYS include `-ngl <N>` in `extraArgs`** — calculate using the formula from the Hardware Context section (per-layer VRAM from file size / layer count, then max layers from weight budget / per-layer VRAM). 7B models at Q4 usually fit entirely → `-ngl -1`.

**Field reference:**
| Field | Required | Description |
|-------|----------|-------------|
| `modelPath` | yes | Full path to the GGUF file |
| `mmprojPath` | no | Multimodal projection file path |
| `extraArgs` | no | Model-specific llama-server flags (including `-ngl`) |
| `name` | yes | Human-readable label for opencode |
| `tools` | no (default: true) | Tool-calling capability |
| `reasoning` | no (default: false) | Reasoning capability |

The `-c 0` base flag is added automatically by the module. `-ngl` is NOT a base flag — you must specify it per model.

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

### GPU offload (`-ngl`)

- **Not a global default** — `-ngl` is deliberately excluded from the module's base flags
- Must be specified per model in `extraArgs` based on VRAM budget
- **Formula** (from [bmdpat.com/blog/llama-cpp-n-gpu-layers-explained-2026](https://bmdpat.com/blog/llama-cpp-n-gpu-layers-explained-2026)):
  - Look up layer count (`llama.block_count` in load log, or `num_hidden_layers` in model's `config.json`)
  - Per-layer VRAM = GGUF file size (bytes) / layer_count
  - Max layers = (available_weight_budget) / per_layer_VRAM
  - On this system: weight budget ≈ 5 GB (after OS/KV cache overhead)
- **For multimodal models (Gemma 4 E4B)**: the mmproj takes additional ~1 GB VRAM — reduce `-ngl` further or expect OOM
- **MoE models**: `-ngl` offloads transformer layers; expert weights are handled separately. The formula still applies but be more conservative (expert layers increase memory pressure)
- **When unsure**: prefer a lower `-ngl` (run today) over a theoretical maximum (risk OOM)

### KV cache calculation

The KV cache is the main variable in VRAM budgeting. **Never trust the formula alone** — the theoretical per-token cost consistently underestimates by 1.5–2×. Always verify with a smoke test.

**Step 1 — Find model architecture details:**

Look up from `config.json` or the model card:
- `num_hidden_layers` (total layers)
- `num_key_value_heads` (KV heads — NOT `num_attention_heads`; GQA models have fewer KV heads)
- `head_dim` (size per head, often `hidden_size / num_attention_heads`)
- For hybrid models (Qwen3.8, Gemma 3, etc.): identify which layers use full attention vs. linear/recurrent attention (DeltaNet, etc.) — only attention layers use per-token KV

**Step 2 — Calculate theoretical per-token cost:**

```
KV_per_token = 2 × num_kv_heads × head_dim × dtype_bytes × num_kv_layers
```

Where `dtype_bytes` depends on KV quant:
| KV quant | bytes |
|----------|-------|
| f16 | 2 |
| Q8_0 | 1 |
| Q4_0 | 0.5 |

For **hybrid models**: only count the full attention layers, NOT recurrent/linear layers. E.g., Qwen3.8-27B has 64 layers but only 16 Gated Attention layers store KV.

**Step 3 — Apply safety margin (1.5–2×):**

The theoretical formula consistently underestimates actual VRAM usage due to:
- Buffer alignment and padding
- Flash attention metadata
- Compute graph scratch buffers
- Multiple context slots (`n_slots` × `n_ctx_slot`)
- Recurrent state overhead in hybrid models

Multiply by **1.5–2×** for a realistic estimate. Use 2× for hybrid models to be safe.

**Step 4 — Budget VRAM:**
1. Get target GPU VRAM: `nvidia-smi --query-gpu=name,memory.total --format=csv,noheader`
2. Subtract: model weights (GGUF file size) + mmproj (if present) + CUDA overhead (~500 MB)
3. **Max context** = `available_VRAM / (KV_per_token × safety_margin)`
4. Round down, leave 10% headroom

**Step 5 — Empirical calibration (REQUIRED before finalizing):**

Don't trust the math — launch and measure:
1. Query baseline VRAM: `nvidia-smi --query-gpu=memory.used --format=csv,noheader`
2. Launch server with a small context (`-c 8192`) and target KV quant
3. Query VRAM after load → delta = actual KV allocation
4. Calculate real per-token cost: `actual_KV_delta / context_size`
5. Extrapolate: `available_VRAM / real_per_token = true_max_context`

Then verify at full target context in the final smoke test.

**Example (Qwen3.8-27B, single 5060 Ti):**
- Theoretical: `2 × 4 × 256 × 1 × 16 = 32 KB/token` (Q8_0)
- With 2× safety: 64 KB/token
- Empirically measured: **~52–58 KB/token** at Q8_0
- Q4_0 empirical: **~28 KB/token**
- KV budget: 16 GB − 12.6 GiB weights − 0.5 GiB overhead ≈ 2.9 GiB for KV
- Q8_0 max: ~48–53k tokens | Q4_0 max: ~100–108k tokens

### Smoke test

After adding a model entry, validate it actually loads and runs before telling the user to deploy.

**Step 1 — Query baseline GPU state:**
```bash
nvidia-smi --query-gpu=index,name,memory.used,memory.total --format=csv,noheader
```
Record the baseline VRAM usage on each GPU.

**Step 2 — Start standalone llama-server:**
Use `hub` to launch a temporary server with the exact flags from the model config:
```
hub start:
  name: ridge-test
  application: llama-server
  args: ["-m", "<modelPath>", "-ngl", "-1", "-c", "<contextSize>", ...]
  ready: { port: <port>, timeout: 120 }
```
Include `--mmproj` if the model has one. Use `-ts <split>` for tensorSplit.

**Step 3 — Verify loading succeeded:**
```bash
hub logs --name ridge-test --lines 60
```
Check for:
 ✅ `srv load_model: loading model` appears
 ✅ No `cudaMalloc failed: out of memory` errors
 ✅ Server reports `ready`

**Step 4 — Verify GPU assignment:**
```bash
nvidia-smi --query-gpu=index,name,memory.used,memory.total --format=csv,noheader
```
Compare VRAM usage against baseline. The target GPU should show increased usage consistent with the model weights + KV cache. If the wrong GPU shows usage, the `tensorSplit` is misconfigured.

**Step 5 — Test inference:**
```bash
curl -s http://127.0.0.1:<port>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "test", "messages": [{"role": "user", "content": "hi"}], "max_tokens": 50}'
```
A non-empty response confirms the model can generate tokens, not just load weights.

**Step 6 — Stop server and report:**
```
hub stop --name ridge-test
```
Report: load status, VRAM usage per GPU, inference result, and any warnings from logs.

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
  Flags (add to extraArgs): --jinja -fa on
  -ngl: 9.16 GB / 40 layers = 229 MB/layer → 5.0 GB / 0.229 GB ≈ 21 layers → -ngl 20

Confirmed? (y/n) y

⬇️  Downloading Qwen3-14B-UD-Q4_K_XL.gguf (9.16 GB)...
   [████████████████████████] 100%

✅ Downloaded to: /Users/zg47ma/.cache/huggingface/hub/models--unsloth--Qwen3-14B-GGUF/snapshots/a04a82c4.../Qwen3-14B-UD-Q4_K_XL.gguf

📝 Updated lcars.models in home.nix:
   + "unsloth/Qwen3-14B-GGUF:UD-Q4_K_XL" = {
       modelPath = "...";
extraArgs = [ "-ngl" "20" "--jinja" "-fa" "on" ];
       name = "Qwen3 14B UD Q4_K_XL";
       tools = true;
       reasoning = false;
     };
   (llama-swap + opencode updated automatically)

✅ Validation passed (just check)

Next: run `just deploy` to activate the configuration.
```
