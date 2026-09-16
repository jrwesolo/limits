# Shared helpers for the scripts in this directory. Source it, do not execute
# it:
#
#   source "$(dirname "${BASH_SOURCE[0]}")/lib.bash"
#
# These are shared rather than duplicated because the three scripts have to
# agree on which cookbook and which version they are talking about. If the pull
# request check and the release parsed metadata.rb differently, a release could
# tag a version that was never validated; if the release and the publish
# disagreed, the tag and the artifact on Supermarket could describe different
# code.

# Prints the name declared in a cookbook metadata file, defaulting to the
# metadata.rb in the current directory.
cookbook_name() {
  local file=${1:-metadata.rb}
  sed -n "s/^name[[:space:]]*'\([^']*\)'.*/\1/p" "${file}"
}

# Prints the version declared in a cookbook metadata file, defaulting to the
# metadata.rb in the current directory.
cookbook_version() {
  local file=${1:-metadata.rb}
  sed -n "s/^version[[:space:]]*'\([^']*\)'.*/\1/p" "${file}"
}

# Succeeds when the given tag (including its leading v) already exists on the
# remote. Requires GITHUB_REPOSITORY and an authenticated gh.
tag_exists() {
  local tag=$1
  gh api "repos/${GITHUB_REPOSITORY}/git/ref/tags/${tag}" >/dev/null 2>&1
}

# Prints the body of the changelog section for the given tag, without the
# heading, its setext underline, or leading blank lines. Trailing blank lines
# are left for command substitution to strip. The exit pattern also catches the
# link reference block at the foot of the file, which is what bounds the oldest
# section.
changelog_notes() {
  local tag=$1
  local file=${2:-CHANGELOG.md}
  awk -v tag="${tag}" '
    $0 == "[" tag "]"                        { found = 1; underline = 1; next }
    found && underline                       { underline = 0; next }
    found && /^\[v[0-9]+\.[0-9]+\.[0-9]+\]/  { exit }
    found                                    { print }
  ' "${file}" | sed -e '/./,$!d'
}

# Records a key=value workflow output. Does nothing when the script is run by
# hand outside GitHub Actions, so the scripts stay directly runnable.
set_output() {
  if [[ -n ${GITHUB_OUTPUT:-} ]]; then
    printf '%s\n' "$1" >> "${GITHUB_OUTPUT}"
  fi
}
