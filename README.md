# ansible

[![update](https://github.com/ai-swfactory-oss/ansible/actions/workflows/update.yml/badge.svg)](https://github.com/ai-swfactory-oss/ansible/actions/workflows/update.yml)
[![build](https://github.com/ai-swfactory-oss/ansible/actions/workflows/build.yml/badge.svg)](https://github.com/ai-swfactory-oss/ansible/actions/workflows/build.yml)

[ansible-core](https://github.com/ansible/ansible) (`ansible-playbook`, `ansible-inventory`, `ansible-galaxy`) and [ansible-lint](https://github.com/ansible/ansible-lint) as npm packages, with no Python needed on the host.
- Each platform package carries a pinned [python-build-standalone](https://github.com/astral-sh/python-build-standalone) CPython 3.13 with one environment holding both tools, installed from a fully hash-locked set of binary wheels.
- The tree is built on that platform's own runner and published to GitHub Packages.
- There is no download at install time and there are no install scripts.

| Package | What |
|---|---|
| `@ai-swfactory-oss/ansible` | Thin: the four bins, plus `binaryPath(tool)`, `tools` and `upstreamVersion` for Node. Depends optionally on the four platform packages, pinned exactly. |
| `@ai-swfactory-oss/ansible-<darwin\|linux>-<arm64\|x64>` | `bin/<tool>` stubs, `python/` (CPython 3.13 with the locked distributions), `LICENSES/` |

The package version follows **ansible-core**. A bump of ansible-lint alone, a dependency re-lock, or a new CPython build is a re-pack, `<core version>-r.<n>`.

## Install and use

GitHub Packages needs the scope line in your project's `.npmrc` (`@ai-swfactory-oss:registry=https://npm.pkg.github.com`) and a `read:packages` token in your user `~/.npmrc`; see the [shfmt wrapper](https://github.com/ai-swfactory-oss/shfmt#install). Then:

```sh
npm install --save-dev @ai-swfactory-oss/ansible
npx ansible-playbook --version
```

```js
const { spawnSync } = require('node:child_process');
const { binaryPath } = require('@ai-swfactory-oss/ansible');

spawnSync(binaryPath('ansible-lint'), ['--offline'], {
  stdio: 'inherit',
  env: { ...process.env, ANSIBLE_HOME: '/tmp/my-run/ansible-home', ANSIBLE_LOCAL_TEMP: '/tmp/my-run/tmp' },
});
```

- `binaryPath(tool)` takes one of `ansible-galaxy`, `ansible-inventory`, `ansible-lint` or `ansible-playbook`, and returns a POSIX `sh` stub running `python/bin/python3 -I -m <module>`. `-I` isolates the run from the host Python.
- **The package sets no ansible runtime directory** and bundles no collections. Pass `ANSIBLE_HOME`, `ANSIBLE_LOCAL_TEMP` and `ANSIBLE_COLLECTIONS_PATH` yourself; otherwise ansible's own defaults apply, unchanged. ansible-lint may install collections at run time unless `--offline` is given.
- The tools are POSIX-only; there is no Windows control node.

## What is pinned, and how it is checked

- **Interpreter.** Same as the [yamllint wrapper](https://github.com/ai-swfactory-oss/yamllint#what-is-pinned-and-how-it-is-checked): the `install_only_stripped` and `full` archives are pinned per platform, from GitHub digests cross-checked against `SHA256SUMS`.
- **Distributions.** `locks/<platform>.txt` lists every distribution, transitive dependencies included, each with the sha256 PyPI publishes for that platform's wheel.
  - The `lock` workflow regenerates a lock on each platform's own runner when a bump marks it stale. It resolves `ansible-core==…` and `ansible-lint==…` with binary wheels only, downloads each file, and requires its hash to equal the index's.
  - All four locks hold the same versions. cryptography 49 and later publish no Intel macOS wheel, so `upstream.json` pins cryptography 48.0.1 for every platform; `update` raises it as soon as a newer release ships an x86_64 macOS wheel again.
  - On every pull request, `lock` verifies each hash against PyPI.
  - A dependency with no binary wheel for a platform fails the lock, so nothing is ever built from source.
  - The install uses `--require-hashes --only-binary=:all: --no-deps`, followed by `pip check`.
- **Provenance.** Every published tarball has a GitHub build-provenance attestation.

## Corresponding source (GPL-3.0-or-later)

Every GitHub release carries:
- the sdists of the three GPL-licensed distributions it ships, ansible-core, ansible-lint and yamllint, and of MPL-2.0 pathspec, exactly as published on PyPI;
- `build-scripts.tar.gz`.

Each package's `NOTICE` names that release. Every other bundled component is permissive and GPL-compatible, and its licence texts are in `LICENSES/<distribution>/`.

**Releases are never deleted while their package version is served.**

## Workflows

The workflows are those of the yamllint wrapper, unchanged (`scripts/` and `.github/workflows/` are shared); see that README for details. `update` follows both requirements on PyPI and python-build-standalone.

## License

- The scripts and workflows in this repository are **MIT** (see [`LICENSE`](LICENSE)).
- The **npm packages are GPL-3.0-or-later**.

"Ansible" is a trademark of Red Hat, Inc. This project is not affiliated with Red Hat, the Ansible project or the Python Software Foundation.
