# Shared assertions for the CI check tests. Bash 3.2 compatible so that the
# same file runs on macOS and in a bash 5 container.

PASS=0
FAIL=0

# Auto gc off for every git this harness drives. Left on, git schedules a
# detached gc after a clone or a fetch, and that gc rewrites .git/shallow
# under the next `git fetch --depth=1`, which then dies with "shallow file
# has changed since we read it". Measured: six of six e2e runs failed that
# way with it on, none with it off. Nothing under test is about gc, so the
# race only ever produces a failure that says nothing about the code.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=gc.auto GIT_CONFIG_VALUE_0=0

# The checkout under test. Derived from this file's own location so that a
# single suite runs by hand exactly as run-all runs it, and overridable so a
# suite can be pointed at a different tree.
: "${REPO_ROOT:="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"}"

repo_root() { printf '%s' "${REPO_ROOT}"; }

# jq's exit status for input it cannot parse, measured rather than named. It
# is 5 in jq 1.7 and 4 in jq 1.6, so a suite that writes the number is green
# on a workstation and red in a container for a reason that has nothing to do
# with the script under test. What the assertions care about is that the
# failure is the one jq produces and not some other non-zero status.
# shellcheck disable=SC2034  # read by the suites that source this file
JQ_PARSE_STATUS="$(printf 'not json' | jq . >/dev/null 2>&1; echo $?)"

start() {
  LAST_OUT=''
  LAST_STATUS=0
}

# Runs a command, capturing combined output and status without tripping set -e.
run() {
  set +e
  LAST_OUT="$("$@" 2>&1)"
  LAST_STATUS=$?
  set -e
}

ok() {
  PASS=$((PASS + 1))
  printf '  \033[32mok\033[0m   %s\n' "$1"
}

bad() {
  FAIL=$((FAIL + 1))
  printf '  \033[31mFAIL\033[0m %s\n' "$1"
  printf '%s\n' "${LAST_OUT}" | sed -e 's/^/         | /'
}

expect_status() {
  local want=$1 what=$2
  if [[ ${LAST_STATUS} -eq ${want} ]]; then
    ok "${what} (exit ${LAST_STATUS})"
  else
    bad "${what}: wanted exit ${want}, got ${LAST_STATUS}"
  fi
}

expect_pass() { expect_status 0 "$1"; }

# No expect_fail taking any non-zero status. A suite run against a checkout
# with no main branch had check-version die at 128 inside git fetch, never
# reaching the check under test, and every such assertion reported green on
# it. Name the status: 1 where the script refuses on purpose, and the tool's
# own code where set -e propagates one, which is the fact worth pinning.

expect_out() {
  local needle=$1 what=$2
  case ${LAST_OUT} in
    *"${needle}"*) ok "${what}" ;;
    *) bad "${what}: output does not contain '${needle}'" ;;
  esac
}

expect_no_out() {
  local needle=$1 what=$2
  case ${LAST_OUT} in
    *"${needle}"*) bad "${what}: output unexpectedly contains '${needle}'" ;;
    *) ok "${what}" ;;
  esac
}

# Editing a file under test, in the one way that cannot lie.
#
# Every one of these refuses to continue unless the file actually changed. An
# edit that quietly matches nothing leaves the original behind, and a script
# that was never mutated passing the case below reads exactly like a check
# that caught the mutant: the conclusion drawn is the opposite of the truth.
# This has happened here twice, once through a GNU-only sed address that BSD
# sed accepted and ignored, and once through a pattern that stopped matching
# after the code moved.
#
#   mutate_file  FILE  OLD  NEW   literal substitution, in place
#   mutant_of    SRC  DST  OLD  NEW   the same, into an executable copy
#   replace_re   FILE  REGEX  REPLACEMENT   extended regex, \1 backreferences
#   delete_lines FILE  REGEX   drops every line the regex matches
#
# Regexes are Python's, anchored per line, so ^ and $ mean what they do in
# sed. Written in Python rather than sed because the two seds differ on both
# addresses and in-place editing, and a test suite that behaves differently on
# a workstation than on the runner is worse than no suite.
_edit() {
  python3 - "$@" <<'EDIT'
import re
import sys

mode, src, dst, pattern, replacement = sys.argv[1:6]
before = open(src).read()

if mode == 'literal':
    after = before.replace(pattern, replacement)
elif mode == 'regex':
    after = re.sub(pattern, replacement, before, flags=re.M)
elif mode == 'delete':
    matches = re.compile(pattern).search
    after = ''.join(l for l in before.splitlines(True) if not matches(l))
else:
    sys.exit('unknown edit mode %r' % mode)

if after == before:
    sys.exit('edit changed nothing in %s: %r' % (src, pattern))

open(dst, 'w').write(after)
EDIT
}

mutate_file()  { _edit literal "$1" "$1" "$2" "$3"; }
replace_re()   { _edit regex "$1" "$1" "$2" "$3"; }
delete_lines() { _edit delete "$1" "$1" "$2" ''; }
mutant_of()    { _edit literal "$1" "$2" "$3" "$4" && chmod +x "$2"; }

section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

summary() {
  printf '\n%d passed, %d failed\n' "${PASS}" "${FAIL}"
  ((FAIL == 0))
}
