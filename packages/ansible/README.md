# @ai-swfactory-oss/ansible

ansible-core (`ansible-playbook`, `ansible-inventory`, `ansible-galaxy`) and ansible-lint with their own Python. The matching platform package carries a pinned CPython 3.13 with both tools installed from hash-locked wheels. No Python is needed on the host, nothing is downloaded at install time, and there are no install scripts.

Platforms: `linux-x64`, `linux-arm64`, `darwin-x64`, `darwin-arm64`.

```sh
npm install --save-dev @ai-swfactory-oss/ansible   # scope @ai-swfactory-oss -> https://npm.pkg.github.com
npx ansible-playbook --version
```

```js
const { binaryPath, tools, upstreamVersion } = require('@ai-swfactory-oss/ansible');
// binaryPath('ansible-lint'): the stub for this os and cpu (bundled CPython, -I, isolated from the host Python)
// upstreamVersion: the ansible-core version
```

The package sets no ansible runtime directory and bundles no collections: pass `ANSIBLE_HOME` (and `ANSIBLE_LOCAL_TEMP`, `ANSIBLE_COLLECTIONS_PATH`) in the child environment.

`binaryPath()` throws `UnknownToolError`, `UnsupportedPlatformError` or `PlatformPackageMissingError`.

License: GPL-3.0-or-later. The corresponding source (the ansible-core, ansible-lint and yamllint sdists, and the build scripts) is attached to the GitHub release of each version. Bundled licences are in the platform package's `LICENSES/`. "Ansible" is a trademark of Red Hat, Inc.; this package is not affiliated with Red Hat.
