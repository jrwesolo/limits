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
  cookbook_field name "${1:-metadata.rb}"
}

# Prints the version declared in a cookbook metadata file, defaulting to the
# metadata.rb in the current directory.
cookbook_version() {
  cookbook_field version "${1:-metadata.rb}"
}

# Prints the first single-quoted value declared for the given field in a
# cookbook metadata file.
#
# The first, and not every match. A substitution prints one line per match,
# so a metadata file naming a field twice would hand the caller two values
# where it reads one, and every caller here treats the result as a single
# string. Reading it in the shell also matches how check-version finds the
# newest changelog heading, rather than two ways of doing one thing.
cookbook_field() {
  local field=$1 file=$2 line
  local pattern="^${field}[[:space:]]+'([^']*)'"

  while IFS= read -r line; do
    if [[ ${line} =~ ${pattern} ]]; then
      printf '%s\n' "${BASH_REMATCH[1]}"
      return 0
    fi
  done < "${file}"

  return 1
}

# Succeeds when the given tag (including its leading v) already exists on the
# remote. Requires GITHUB_REPOSITORY and an authenticated gh.
#
# A request that fails is not an answer. Reading every failure as "no such
# tag", which is what discarding gh's output does, lets a rate limit or a
# network blip through the check that exists to catch an already released
# version, and sends the release job on to fail on a symptom instead. Only a
# 404 means the tag is absent; anything else stops the caller, since neither
# has anything useful to do with a third outcome.
tag_exists() {
  local tag=$1 out
  out="$(gh api "repos/${GITHUB_REPOSITORY}/git/ref/tags/${tag}" 2>&1)" && return 0

  [[ ${out} == *'(HTTP 404)'* ]] && return 1

  echo "::error::Could not ask GitHub whether ${tag} exists: ${out}" >&2
  exit 1
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
