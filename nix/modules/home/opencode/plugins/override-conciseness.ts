import type { Plugin } from "@opencode-ai/plugin";

export const OverrideConciseness: Plugin = async () => {
  return {
    "experimental.chat.system.transform": async (_input, output) => {
      const changed = output.system.map((s) =>
        s
          .replace(/# Tone and style[\s\S]*?(?=\n# )/g, "")
          .replace(/You MUST answer concisely with fewer than 4 lines[\s\S]*?(?=\n\n|\n# |$)/g, ""),
      );
      output.system.length = 0;
      output.system.push(...changed);
    },
  };
};
