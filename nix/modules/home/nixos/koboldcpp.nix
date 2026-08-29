{
  config,
  pkgs,
  lib,
  ...
}:

let
  models = config.lcars.models or { };
  cfgDir = "${config.xdg.configHome}/koboldcpp";
  port = 5001;

  # nixpkgs installs all *.embd assets flat in bin/, but koboldcpp 1.110 loads
  # its embedded web UIs (Lite, LCPP, docs, SD UI) from bin/embd_res/. Move
  # only the six UI assets there; the tokenizer/taesd .embd files are read
  # from bin/ directly and must stay put.
  koboldcpp = pkgs.unstable.koboldcpp.overrideAttrs (old: {
    version = "1.119";
    src = pkgs.fetchFromGitHub {
      owner = "LostRuins";
      repo = "koboldcpp";
      tag = "v1.119";
      hash = "sha256-WJVbzh4BGLiQdd/rzqSe2Q9PGqMpsqmQNQf33INJkd8=";
    };
    postInstall = (old.postInstall or "") + ''
      mkdir -p "$out/bin/embd_res"
      for f in klite kcpp_docs kcpp_sdui lcpp.gz kcpp_musicui qwen3tts_voices_json; do
        [ -e "$out/bin/$f.embd" ] && mv "$out/bin/$f.embd" "$out/bin/embd_res/$f.embd"
      done
    '';
  });

  # Make a filesystem-safe name from the (slash/colon-bearing) model key.
  sanitize = k: builtins.replaceStrings [ "/" ":" " " "@" ] [ "_" "_" "_" "_" ] k;

  # Chat Completions Adapter presets for koboldcpp's OpenAI-compatible /v1
  # endpoint (overrides the default Alpaca fallback). Each maps to the
  # model's native chat format.
  adapterPresets = {
    chatml = {
      system_start = "<|im_start|>system\n";
      system_end = "<|im_end|>\n";
      user_start = "<|im_start|>user\n";
      user_end = "<|im_end|>\n";
      assistant_start = "<|im_start|>assistant\n";
      assistant_end = "<|im_end|>\n";
    };
    gemma = {
      system_start = "<start_of_turn>system\n";
      system_end = "<end_of_turn>\n";
      user_start = "<start_of_turn>user\n";
      user_end = "<end_of_turn>\n";
      assistant_start = "<start_of_turn>model\n";
      assistant_end = "<end_of_turn>\n";
    };
  };

  # Generate a .adapter.json for models that declare a chatAdapter preset.
  mkAdapter =
    name: model:
    let
      key = model.chatAdapter or null;
      preset = if key == null then null else adapterPresets.${key} or null;
    in
    if preset == null then
      null
    else
      pkgs.writeText "${sanitize name}.adapter.json" (builtins.toJSON preset);

  # Translate the engine-agnostic lcars.models fields into a KoboldCpp
  # .kcpps launcher config. koboldcpp 1.112+ uses --quantkv <type>
  # (f16/bf16/q8_0/q5_1/q4_0); we reuse the lcars.models kvQuant.k value
  # to set it. extraArgs has no KoboldCpp equivalent and is dropped.
  mkKcpps =
    name: model:
    let
      gpulayers = if model.gpuLayers == -1 then 999 else model.gpuLayers;
    in
    pkgs.writeText "${sanitize name}.kcpps" (
      builtins.toJSON (
        {
          model_param = model.modelPath;
          port = port;
          host = "127.0.0.1";
          contextsize = model.contextSize;
          gpulayers = gpulayers;
          flashattention = model.flashAttention;
        }
        // lib.optionalAttrs (model.mmprojPath != null) { mmproj = model.mmprojPath; }
        // lib.optionalAttrs (model.jinja or false) { jinja = model.jinja; }
        // lib.optionalAttrs (model.useswa or false) { useswa = model.useswa; }
        // lib.optionalAttrs (model.kvQuant or null != null) { quantkv = model.kvQuant.k; }
        // lib.optionalAttrs (model.tensorSplit or null != null) { tensor_split = model.tensorSplit; }
        // lib.optionalAttrs (model.cudaDevices or null != null && (model.tensorSplit or null == null)) (
          # Backward-compat: derive a native tensor_split from cudaDevices so old
          # configs keep pinning. Builds a vector over physical GPU order (router
          # leaves CUDA_VISIBLE_DEVICES unset) where included GPUs get weight 1 and
          # excluded GPUs get 0, e.g. "1" -> [0,1], "0,1" -> [1,1].
          let
            cudaInts = map builtins.toInt (lib.splitString "," model.cudaDevices);
            maxIdx = lib.lists.foldl' (a: b: if b > a then b else a) 0 cudaInts;
            derived = map (i: if lib.lists.elem i cudaInts then 1 else 0) (
              builtins.genList (x: x) (maxIdx + 1)
            );
          in
          {
            tensor_split = derived;
          }
        )
      )
    );

  manifest = pkgs.writeText "koboldcpp-manifest.json" (
    builtins.toJSON (builtins.mapAttrs (name: _: sanitize name) models)
  );

  koboldSelect = pkgs.writeShellApplication {
    name = "kobold-select";
    runtimeInputs = [
      koboldcpp
      pkgs.jq
      pkgs.fzf
    ];
    text = ''
      set +e
      CFG="${cfgDir}"
      MANIFEST="$CFG/manifest.json"
      PORT=${toString port}

      export LD_PRELOAD="/run/opengl-driver/lib/libcuda.so''${LD_PRELOAD:+:$LD_PRELOAD}"

      [ -f "$MANIFEST" ] || { echo "No koboldcpp models configured (manifest.json missing at $MANIFEST)." >&2; exit 1; }

      pick_model() {
        if command -v fzf >/dev/null 2>&1; then
          jq -r 'keys[]' "$MANIFEST" | fzf --prompt="koboldcpp model> "
        else
          local keys i k choice
          keys=$(jq -r 'keys[]' "$MANIFEST")
          i=1
          echo "Available koboldcpp models:" >&2
          echo "$keys" | while read -r k; do echo "  $i) $k" >&2; i=$((i + 1)); done
          echo "Enter number or model key:" >&2
          read -r choice
          if [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo "$keys" | sed -n "''${choice}p"
          else
            echo "$choice"
          fi
        fi
      }

      ARG="''${1:-}"
      [ -z "$ARG" ] && ARG="$(pick_model)"
      [ -n "$ARG" ] || { echo "No model selected." >&2; exit 1; }

      FNAME=$(jq -r --arg k "$ARG" '.[$k] // empty' "$MANIFEST")
      [ -n "$FNAME" ] || FNAME="$ARG"
      KCPPS="$CFG/$FNAME.kcpps"
      [ -f "$KCPPS" ] || { echo "Config not found: $KCPPS" >&2; exit 1; }

      ADAPTER="$CFG/$FNAME.adapter.json"
      ADAPTER_ARG=()
      [ -f "$ADAPTER" ] && ADAPTER_ARG=(--chatcompletionsadapter "$ADAPTER")

      # Tensor split ratios must be passed as separate argv tokens, not one
      # glued string (koboldcpp argparse expects `--tensor_split 2 1`). Read the
      # native tensor_split key (the single source of truth, shared with router mode).
      mapfile -t TS_VALS < <(jq -r '.tensor_split // [] | .[]' "$KCPPS")
      TS_ARG=()
      if [ ''${#TS_VALS[@]} -gt 0 ]; then
        TS_ARG=(--tensor_split "''${TS_VALS[@]}")
      fi

      echo "Launching koboldcpp (all GPUs visible; tensor_split pins placement)"
      echo "  model : $ARG"
      echo "  config: $KCPPS"
      [ -f "$ADAPTER" ] && echo "  adapter: $ADAPTER"
      echo "  URL   : http://127.0.0.1:$PORT   (Ctrl-C to stop)"
      export PYTHONPATH="${
        pkgs.python3.withPackages (ps: [ ps.jinja2 ])
      }/${pkgs.python3.sitePackages}:''${PYTHONPATH:+:$PYTHONPATH}"
      exec koboldcpp --skiplauncher --usecuda mmq --config "$KCPPS" --host 127.0.0.1 --port "$PORT" "''${ADAPTER_ARG[@]}" "''${TS_ARG[@]}"
    '';
  };

  # Persistent KoboldCpp admin/router instance. This is KoboldCpp's built-in
  # llama-swap-like layer: one always-on process on :5001 that hotswaps
  # between the .kcpps configs in admindir, either by the OpenAI `model` field
  # (router mode) or via the Admin panel in KoboldAI Lite. --adminunloadtimeout
  # mirrors a llama-swap ttl (600s) so idle models free their VRAM.
  koboldRouter = pkgs.writeShellApplication {
    name = "kobold-router";
    runtimeInputs = [ koboldcpp ];
    text = ''
      set -euo pipefail
      CFG="${cfgDir}"
      PORT=5001

      # Mirror kobold-select's runtime environment so CUDA and Jinja-based chat
      # templates work for whatever model the router loads on demand.
      export LD_PRELOAD="/run/opengl-driver/lib/libcuda.so''${LD_PRELOAD:+:$LD_PRELOAD}"
      export PYTHONPATH="${
        pkgs.python3.withPackages (ps: [ ps.jinja2 ])
      }/${pkgs.python3.sitePackages}:''${PYTHONPATH:+:$PYTHONPATH}"

      # CUDA_VISIBLE_DEVICES is intentionally left unset so the router can use
      # every GPU and honor each .kcpps tensor_split. Per-model GPU pinning
      # (lcars_cuda_devices) is NOT honored by admin/router mode, which only
      # swaps .kcpps configs through the admin API, not our custom keys.

      exec koboldcpp --skiplauncher --usecuda mmq \
        --admin --admindir "$CFG" --routermode --nomodel \
        --adminunloadtimeout 600 \
        --host 127.0.0.1 --port "$PORT"
    '';
  };
in
lib.mkIf (models != { }) {
  home.packages = [
    koboldcpp
  ]
  ++ [
    koboldSelect
    koboldRouter
  ];

  xdg.configFile = lib.mkMerge (
    [ { "koboldcpp/manifest.json".source = manifest; } ]
    ++ builtins.attrValues (
      builtins.mapAttrs (
        name: model:
        let
          adapter = mkAdapter name model;
          extra =
            if adapter == null then
              { }
            else
              {
                "koboldcpp/${sanitize name}.adapter.json".source = adapter;
              };
        in
        { "koboldcpp/${sanitize name}.kcpps".source = mkKcpps name model; } // extra
      ) models
    )
  );

  systemd.user.services."kobold-router" = {
    Unit = {
      Description = "KoboldCpp admin/router model server";
      After = [ "network.target" ];
    };
    Service = {
      ExecStart = "${koboldRouter}/bin/kobold-router";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
