#!/usr/bin/env bash
#
# Copy this service template into a new directory to start a new service.
#
# Usage: scripts/new-service.sh /absolute/path/to/new-service
#
# Copies every file git tracks plus untracked files that are not ignored, so
# .git, apm_modules/, and other ignored local state are left behind. The
# destination must not exist or must be an empty directory.

set -euo pipefail

usage() {
	printf 'usage: %s /absolute/path/to/new-service\n' "$(basename "$0")" >&2
	exit 2
}

die() {
	printf 'error: %s\n' "$1" >&2
	exit 1
}

[ "$#" -eq 1 ] || usage
dest=$1

case "$dest" in
/*) ;;
*) die "destination must be an absolute path: $dest" ;;
esac

src=$(cd "$(dirname "$0")/.." && pwd)
self=scripts/$(basename "$0")

created=false
if [ -e "$dest" ]; then
	[ -d "$dest" ] || die "destination exists and is not a directory: $dest"
	[ -z "$(ls -A "$dest")" ] || die "destination is not empty: $dest"
else
	mkdir -p "$dest"
	created=true
fi
dest=$(cd "$dest" && pwd)

case "$dest/" in
"$src"/*)
	[ "$created" = true ] && rmdir "$dest"
	die "destination must be outside the template: $dest"
	;;
esac

# List tracked and untracked-but-not-ignored files, skipping files deleted from
# the working tree and this script, which new services do not need.
git -C "$src" ls-files -z --cached --others --exclude-standard |
	while IFS= read -r -d '' f; do
		[ "$f" = "$self" ] && continue
		[ -e "$src/$f" ] || [ -L "$src/$f" ] || continue
		printf '%s\0' "$f"
	done |
	tar -C "$src" --null -T - -cf - |
	tar -C "$dest" -xf -

rmdir "$dest/scripts" 2>/dev/null || true

printf 'Created new service at %s\n\n' "$dest"
printf 'Next steps:\n'
printf '  cd %s\n' "$dest"
printf '  git init\n'
printf '  Ask your agent to set up the project (it will follow SETUP.md).\n'
