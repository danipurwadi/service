#!/usr/bin/env bash
#
# Copy this service template into a new directory to start a new service.
#
# Usage: scripts/new-service.sh /absolute/path/to/new-service
#
# Copies every file git tracks plus untracked files that are not ignored, so
# .git, apm_modules/, and other ignored local state are left behind. The
# destination may already contain files; any file that already exists there is
# kept as is and not overwritten.

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
# the working tree, this script (new services do not need it), and files that
# already exist in the destination.
git -C "$src" ls-files -z --cached --others --exclude-standard |
	while IFS= read -r -d '' f; do
		[ "$f" = "$self" ] && continue
		[ -e "$src/$f" ] || [ -L "$src/$f" ] || continue
		if [ -e "$dest/$f" ] || [ -L "$dest/$f" ]; then
			printf 'skipped (already exists): %s\n' "$f" >&2
			continue
		fi
		printf '%s\0' "$f"
	done |
	tar -C "$src" --null -T - -cf - |
	tar -C "$dest" -xf -

printf 'Copied service template into %s\n\n' "$dest"
printf 'Next steps:\n'
printf '  cd %s\n' "$dest"
[ -e "$dest/.git" ] || printf '  git init\n'
printf '  Ask your agent to set up the project (it will follow SETUP.md).\n'
