'use strict';

const path = require('node:path');

const pkg = require('./package.json');

const SCOPE = '@ai-swfactory-oss';
const PREFIX = `${SCOPE}/ansible-`;

/** The ansible-core version this package runs, without any -r.N re-pack suffix. */
const upstreamVersion = pkg.version.replace(/-r\.\d+$/, '');

/** The tools a platform package carries (ansible-galaxy, ansible-inventory, ansible-lint, ansible-playbook). */
const tools = Object.freeze([...(pkg.tools || [])].sort());

/** The `<os>-<cpu>` platforms a package is published for, from the exactly pinned optional dependencies. */
const supportedPlatforms = Object.freeze(
  Object.keys(pkg.optionalDependencies || {})
    .filter((name) => name.startsWith(PREFIX))
    .map((name) => name.slice(PREFIX.length))
);

/** No ansible package is published for this os and cpu. */
class UnsupportedPlatformError extends Error {
  constructor(platform, arch) {
    super(
      `@ai-swfactory-oss/ansible: no ansible package is published for os ${platform} and cpu ${arch}; ` +
        `supported: ${supportedPlatforms.join(', ')}`
    );
    this.name = 'UnsupportedPlatformError';
    this.platform = platform;
    this.arch = arch;
  }
}

/** A package is published for this os and cpu, but it is not installed. */
class PlatformPackageMissingError extends Error {
  constructor(platform, arch, packageName) {
    super(
      `@ai-swfactory-oss/ansible: ${packageName} is not installed for os ${platform} and cpu ${arch}; ` +
        'reinstall without --omit=optional / --no-optional, or from a lockfile made on this platform'
    );
    this.name = 'PlatformPackageMissingError';
    this.platform = platform;
    this.arch = arch;
    this.packageName = packageName;
  }
}

/** The tool is not one this package carries. */
class UnknownToolError extends Error {
  constructor(tool) {
    super(`@ai-swfactory-oss/ansible: no tool ${tool}; known: ${tools.join(', ')}`);
    this.name = 'UnknownToolError';
    this.tool = tool;
  }
}

/** Name of the platform package for this os and cpu. */
function platformPackage(platform = process.platform, arch = process.arch) {
  return `${PREFIX}${platform}-${arch}`;
}

/**
 * Absolute path of `tool` for this os and cpu: a POSIX sh stub that runs it on the CPython bundled in the platform
 * package, isolated from the host Python. Spawn it directly. The package sets no ansible runtime directory: pass
 * ANSIBLE_HOME (and ANSIBLE_LOCAL_TEMP, ANSIBLE_COLLECTIONS_PATH) in the child environment yourself.
 * Throws UnknownToolError, UnsupportedPlatformError or PlatformPackageMissingError.
 */
function binaryPath(tool, platform = process.platform, arch = process.arch) {
  if (!tools.includes(tool)) throw new UnknownToolError(tool);
  if (!supportedPlatforms.includes(`${platform}-${arch}`)) throw new UnsupportedPlatformError(platform, arch);
  const name = platformPackage(platform, arch);
  let dir;
  try {
    dir = path.dirname(require.resolve(`${name}/package.json`));
  } catch {
    throw new PlatformPackageMissingError(platform, arch, name);
  }
  return path.join(dir, 'bin', tool);
}

module.exports = {
  binaryPath,
  platformPackage,
  PlatformPackageMissingError,
  supportedPlatforms,
  tools,
  UnknownToolError,
  UnsupportedPlatformError,
  upstreamVersion,
};
