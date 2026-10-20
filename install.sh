#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

pref_dirs=(
	/Applications/Firefox.app/Contents/Resources/defaults/pref
	/usr/lib/firefox/defaults/pref
	/usr/lib64/firefox/defaults/pref
	#/usr/lib/firefox-esr/defaults/pref
	/usr/lib/firefox-beta/defaults/pref
	/usr/lib/firefox-devedition/defaults/pref
	/usr/lib/firefox-developer-edition/defaults/pref
	/usr/lib/firefox-nightly/defaults/pref
	/usr/lib/firefox-trunk/defaults/pref
	/opt/firefox/defaults/pref
	/opt/firefox-nightly/defaults/pref
)

if ! command -v dialog >/dev/null 2>&1; then
	echo "dialog is not installed" >&2
	exit 1
fi

items=()
longest=0
for pref_dir in "${pref_dirs[@]}"; do
	[[ -d $pref_dir ]] || continue
	dir=${pref_dir%/defaults/pref}
	items+=("$dir" "" off)
	(( ${#dir} > longest )) && longest=${#dir}
done
if (( ${#items[@]} == 0 )); then
	echo "No Firefox install dir found" >&2
	exit 1
fi

prompt="Install into the checked Firefox installs:"
count=$(( ${#items[@]} / 3 ))
width=$(( longest + 14 > ${#prompt} + 6 ? longest + 14 : ${#prompt} + 6 ))
if ! selected=$(dialog --keep-tite --stdout --separate-output \
	--checklist "$prompt" $(( count + 7 )) "$width" "$count" "${items[@]}"); then
	echo "Cancelled"
	exit 1
fi
if [[ -z $selected ]]; then
	echo "Warning: no Firefox install selected, nothing installed" >&2
	exit 0
fi

while IFS= read -r dir; do
	[[ -n $dir ]] || continue
	pref_dir=$dir/defaults/pref
	install -m 644 autoconfig.js "$pref_dir/autoconfig.js"
	install -m 644 autoconfig.cfg "$dir/autoconfig.cfg"
	install -d -m 755 "$dir/autoconfig"
	install -m 644 autoconfig/restart.cfg "$dir/autoconfig/restart.cfg"
	install -m 644 autoconfig/kill-process.cfg "$dir/autoconfig/kill-process.cfg"
	echo "Installed into $dir"
done <<< "$selected"
