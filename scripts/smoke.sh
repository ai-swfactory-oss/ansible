#!/usr/bin/env bash
# The single-quoted node programs are literal on purpose.
# shellcheck disable=SC2016
# Named test, per platform: installs the packed tarballs into a scratch project,
# as a consumer would, and checks
#   - binaryPath(tool) for all four tools resolves to an executable stub;
#   - ansible-playbook reports upstreamVersion, ansible-lint reports its locked
#     version and that ansible-core;
#   - a localhost playbook (connection: local) runs, with ANSIBLE_HOME in a
#     scratch directory the caller chose;
#   - ansible-lint finds one known violation in a fixture;
#   - a hostile PYTHONPATH changes nothing;
#   - the package carries its licences and points at the corresponding source.
#
#   scripts/smoke.sh <tgzdir> <platform>      e.g. dist/tgz linux-x64
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tgz=$(cd "${1:?usage: smoke.sh <tgzdir> <platform>}" && pwd)
platform=${2:?usage: smoke.sh <tgzdir> <platform>}
core=$(jq -er '.requirements[0] | split("==")[1]' "$root/upstream.json")
lint=$(jq -er '.requirements[1] | split("==")[1]' "$root/upstream.json")
version=$(bash "$root/scripts/pkgver.sh")

launcher="$tgz/ai-swfactory-oss-ansible-$version.tgz"
native="$tgz/ai-swfactory-oss-ansible-$platform-$version.tgz"

# Read tarball contents into files first: `tar ... | grep -q` under pipefail
# fails when grep exits early and tar hits the closed pipe.
scan=$(mktemp -d)
for f in "$launcher" "$native"; do
  test -f "$f" || { echo "smoke: missing $f" >&2; exit 1; }
  tar -xzOf "$f" package/package.json >"$scan/package.json"
  if jq -e '.scripts // {} | keys | any(test("install"))' "$scan/package.json" >/dev/null; then
    echo "smoke: $f declares an install script" >&2; exit 1
  fi
  tar -xzOf "$f" package/NOTICE >"$scan/NOTICE"
  grep -q 'Corresponding source' "$scan/NOTICE" || { echo "smoke: $f NOTICE does not point at the corresponding source" >&2; exit 1; }
done
tar -tzf "$native" >"$scan/contents.txt"
for dist in python-build-standalone ansible_core ansible_lint yamllint cryptography; do
  grep -q "^package/LICENSES/$dist/" "$scan/contents.txt" || { echo "smoke: no licence for $dist" >&2; exit 1; }
done

work=$(mktemp -d)
cd "$work" || exit 1
printf '{"name":"smoke","version":"1.0.0","private":true}\n' >package.json
npm install --no-audit --no-fund "$launcher" "$native"

echo "== binaryPath(tool) and upstreamVersion"
node -e '
  const fs = require("node:fs");
  const ansible = require("@ai-swfactory-oss/ansible");
  const [core] = process.argv.slice(1);
  if (ansible.upstreamVersion !== core) throw new Error(`upstreamVersion ${ansible.upstreamVersion} != ${core}`);
  for (const tool of ansible.tools) {
    const bin = ansible.binaryPath(tool);
    fs.accessSync(bin, fs.constants.X_OK);
    console.log(tool, bin);
  }
' "$core"
bin() { node -p "require('@ai-swfactory-oss/ansible').binaryPath('$1')"; }

export ANSIBLE_HOME="$work/ansible-home"
export ANSIBLE_LOCAL_TEMP="$work/ansible-tmp"
export ANSIBLE_COLLECTIONS_PATH="$work/ansible-home/collections"
export ANSIBLE_NOCOLOR=1

echo "== versions"
"$(bin ansible-playbook)" --version | tee playbook-version.txt
grep -q "core $core" playbook-version.txt || { echo "smoke: ansible-playbook is not core $core" >&2; exit 1; }
# ansible-lint colours its version line even when told not to colour
# findings: ask with NO_COLOR, and strip any ANSI escape that is left.
NO_COLOR=1 "$(bin ansible-lint)" --version >lint-version.raw
esc=$(printf '\033')
sed "s/${esc}\[[0-9;]*m//g" lint-version.raw >lint-version.txt
cat lint-version.txt
grep -q "ansible-lint $lint" lint-version.txt || { echo "smoke: ansible-lint is not $lint" >&2; exit 1; }
grep -q "ansible-core:$core" lint-version.txt || grep -q "ansible-core $core" lint-version.txt ||
  { echo "smoke: ansible-lint does not use core $core" >&2; exit 1; }
"$(bin ansible-galaxy)" --version >galaxy-version.txt
sed -n 1p galaxy-version.txt
"$(bin ansible-inventory)" --version >inventory-version.txt
sed -n 1p inventory-version.txt

echo "== a localhost playbook"
cat >site.yml <<'EOF'
- name: smoke
  hosts: localhost
  connection: local
  gather_facts: false
  tasks:
    - name: say hello
      ansible.builtin.debug:
        msg: "hello from the bundled ansible"
EOF
"$(bin ansible-playbook)" -i localhost, site.yml | tee play.txt
grep -q 'hello from the bundled ansible' play.txt || { echo "smoke: the playbook did not run" >&2; exit 1; }
test -d "$ANSIBLE_HOME" || test -d "$ANSIBLE_LOCAL_TEMP" || { echo "smoke: ansible ignored the caller's directories" >&2; exit 1; }

echo "== ansible-lint: one known violation"
mkdir -p lintme
cat >lintme/play.yml <<'EOF'
- hosts: localhost
  tasks:
    - shell: echo hi
EOF
# The fixture's findings are expected. Under GitHub Actions ansible-lint also
# writes each finding as a workflow error annotation, which makes a passing
# smoke look failing: report in plain pep8 lines and hide the Actions
# environment from this one run, so nothing is annotated.
set +e
(cd lintme && env -u GITHUB_ACTIONS -u GITHUB_WORKFLOW "$(bin ansible-lint)" --offline --nocolor --format pep8 play.yml) >lint.txt 2>&1
rc=$?
set -e
cat lint.txt
[ "$rc" -ne 0 ] || { echo "smoke: ansible-lint passed a playbook with violations" >&2; exit 1; }
grep -qE 'name\[missing\]|name\[play\]' lint.txt || { echo "smoke: ansible-lint did not report the missing name" >&2; exit 1; }

echo "== isolation from the host Python"
mkdir -p hostile/ansible
printf 'raise SystemExit("hostile ansible imported")\n' >hostile/ansible/__init__.py
PYTHONPATH="$work/hostile" "$(bin ansible-playbook)" --version >/dev/null

echo "smoke: $platform OK"
