# zen-import - Sideload exported .xpi files into a Zen profile (macOS)
# Usage: zen-import [PROFILE_DIR] [XPI_DIR]
# Defaults: the install's default profile, and /Volumes/home/zen-export.
# Body for pkgs.writeShellApplication (shebang and strict mode are added by the wrapper).

zen_support="${HOME}/Library/Application Support/Zen"
xpi_dir="${2:-/Volumes/home/zen-export}"

default_profile() {
  # The [Install*] section is what Zen actually launches; Profile Default=1 can differ.
  local rel
  rel="$(awk -F= '/^\[Install/{i=1;next} /^\[/{i=0} i&&$1=="Default"{print $2; exit}' "${zen_support}/profiles.ini")"
  [[ -n "${rel}" ]] || { echo "error: no [Install*] Default in profiles.ini" >&2; exit 1; }
  printf '%s/%s' "${zen_support}" "${rel}"
}

profile="${1:-$(default_profile)}"

[[ -d "${profile}" ]] || { echo "error: profile dir not found: ${profile}" >&2; exit 1; }
[[ -d "${xpi_dir}" ]] || { echo "error: xpi dir not found: ${xpi_dir}" >&2; exit 1; }

# Zen holds .parentlock while the profile is in use; a live copy would be overwritten on exit.
if [[ -e "${profile}/.parentlock" ]] && lsof "${profile}/.parentlock" >/dev/null 2>&1; then
  echo "error: profile is in use, quit Zen first: ${profile}" >&2
  exit 1
fi

shopt -s nullglob
xpis=("${xpi_dir}"/*.xpi)
(( ${#xpis[@]} > 0 )) || { echo "error: no .xpi files in ${xpi_dir}" >&2; exit 1; }

mkdir -p "${profile}/extensions"
for xpi in "${xpis[@]}"; do
  # Firefox requires the filename to equal the add-on ID for sideloading.
  id="$(unzip -p "${xpi}" manifest.json | jq -r '.browser_specific_settings.gecko.id // .applications.gecko.id')"
  [[ -n "${id}" && "${id}" != "null" ]] || { echo "error: no gecko id in ${xpi}" >&2; exit 1; }
  cp "${xpi}" "${profile}/extensions/${id}.xpi"
  echo "installed ${id}"
done

# autoDisableScopes=0: enable sideloaded add-ons without a prompt.
# update.enabled=false: no background update checks (sideloaded add-ons ignore autoUpdateDefault).
# autoUpdateDefault=false: add-ons installed later via the UI start in manual mode.
user_js="${profile}/user.js"
touch "${user_js}"
for line in \
  'user_pref("extensions.autoDisableScopes", 0);' \
  'user_pref("extensions.update.enabled", false);' \
  'user_pref("extensions.update.autoUpdateDefault", false);'; do
  grep -qxF "${line}" "${user_js}" || echo "${line}" >> "${user_js}"
done
echo "done: start Zen to load ${#xpis[@]} extensions"
