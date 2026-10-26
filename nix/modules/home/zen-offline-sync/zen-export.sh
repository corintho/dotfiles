# zen-export - Copy Zen browser .xpi extensions to an SMB share for offline sync
# Reads the extension list from ~/.config/zen-offline-sync/zen-export-config.yaml
# Body for pkgs.writeShellApplication (shebang and strict mode are added by the wrapper).

CONFIG_FILE="${HOME}/.config/zen-offline-sync/zen-export-config.yaml"
SMB_DEST="/smb/home/zen-export"
ZEN_ROOT="${HOME}/.zen"
PROFILES_INI="${ZEN_ROOT}/profiles.ini"

# Print the profile directory Zen uses by default, per profiles.ini.
# Prefers the [Install*] section's Default=<path>; falls back to the
# [ProfileN] section with Default=1. Relative paths resolve against ZEN_ROOT.
detect_profile() {
  local line section="" install_path="" profile_path="" profile_rel=1
  local cur_path="" cur_rel=1 cur_default=0 chosen="" chosen_rel=1

  if [[ ! -f "${PROFILES_INI}" ]]; then
    echo "ERROR: Zen profiles.ini not found: ${PROFILES_INI}" >&2
    return 1
  fi

  # Close out a [ProfileN] section: remember it if it is the default.
  flush_profile() {
    if [[ "${section}" == Profile* && "${cur_default}" == 1 && -z "${profile_path}" ]]; then
      profile_path="${cur_path}"
      profile_rel="${cur_rel}"
    fi
  }

  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%$'\r'}"
    if [[ "${line}" =~ ^\[(.*)\]$ ]]; then
      flush_profile
      section="${BASH_REMATCH[1]}"
      cur_path="" cur_rel=1 cur_default=0
    elif [[ "${line}" =~ ^([^=]+)=(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}" value="${BASH_REMATCH[2]}"
      case "${section}" in
        Install*)
          if [[ "${key}" == "Default" && -z "${install_path}" ]]; then
            install_path="${value}"
          fi
          ;;
        Profile*)
          case "${key}" in
            Path) cur_path="${value}" ;;
            IsRelative) cur_rel="${value}" ;;
            Default) cur_default="${value}" ;;
          esac
          ;;
      esac
    fi
  done < "${PROFILES_INI}"
  flush_profile

  if [[ -n "${install_path}" ]]; then
    # [Install*] Default= is relative to the Zen root unless already absolute.
    chosen="${install_path}"
    chosen_rel=1
    [[ "${chosen}" == /* ]] && chosen_rel=0
  elif [[ -n "${profile_path}" ]]; then
    chosen="${profile_path}"
    chosen_rel="${profile_rel}"
  else
    echo "ERROR: No default profile found in ${PROFILES_INI}" >&2
    return 1
  fi

  if [[ "${chosen_rel}" == 1 ]]; then
    printf '%s\n' "${ZEN_ROOT}/${chosen}"
  else
    printf '%s\n' "${chosen}"
  fi
}

main() {
  local profile_dir profile_ext_dir
  profile_dir=$(detect_profile) || exit 1
  profile_ext_dir="${profile_dir}/extensions"
  if [[ ! -d "${profile_ext_dir}" ]]; then
    echo "ERROR: No extensions/ directory in Zen profile: ${profile_dir}" >&2
    exit 1
  fi
  echo "Detected profile extensions: ${profile_ext_dir}/"

  if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "ERROR: Config file not found: ${CONFIG_FILE}" >&2
    exit 1
  fi

  mkdir -p "${SMB_DEST}"

  local line name="" filename src dst count=0 skipped=0
  # Simple YAML parser: a "- name:" line followed by its "filename:" line
  while IFS= read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
      name="${BASH_REMATCH[1]}"
      # Strip surrounding single or double quotes if present
      name="${name#[\"\']}"
      name="${name%[\"\']}"
    elif [[ "${line}" =~ ^[[:space:]]*filename:[[:space:]]*(.+)$ ]]; then
      filename="${BASH_REMATCH[1]}"
      filename="${filename#[\"\']}"
      filename="${filename%[\"\']}"

      src="${profile_ext_dir}/${filename}"
      dst="${SMB_DEST}/${filename}"

      if [[ -f "${src}" ]]; then
        cp -f "${src}" "${dst}"
        echo "Copied: ${name} -> ${dst}"
        count=$((count + 1))
      else
        echo "WARN: Missing file: ${name} (${filename})" >&2
        skipped=$((skipped + 1))
      fi
    fi
  done < "${CONFIG_FILE}"

  echo "Done: ${count} copied, ${skipped} skipped"
  if (( skipped > 0 )); then
    exit 1
  fi
}

main "$@"
