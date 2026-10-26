/** The ansible-core version this package runs, without any -r.N re-pack suffix. */
export declare const upstreamVersion: string;

/** The tools a platform package carries. */
export declare const tools: readonly string[];

/** The `<os>-<cpu>` platforms a package is published for. */
export declare const supportedPlatforms: readonly string[];

export type Tool = 'ansible-galaxy' | 'ansible-inventory' | 'ansible-lint' | 'ansible-playbook';

/** No ansible package is published for this os and cpu. */
export declare class UnsupportedPlatformError extends Error {
  readonly name: 'UnsupportedPlatformError';
  readonly platform: string;
  readonly arch: string;
}

/** A package is published for this os and cpu, but it is not installed. */
export declare class PlatformPackageMissingError extends Error {
  readonly name: 'PlatformPackageMissingError';
  readonly platform: string;
  readonly arch: string;
  readonly packageName: string;
}

/** The tool is not one this package carries. */
export declare class UnknownToolError extends Error {
  readonly name: 'UnknownToolError';
  readonly tool: string;
}

/** Name of the platform package for this os and cpu (default: this process's). */
export declare function platformPackage(platform?: string, arch?: string): string;

/**
 * Absolute path of `tool` for this os and cpu (default: this process's): a stub running it on the bundled CPython,
 * isolated from the host Python. The package sets no ansible runtime directory; pass ANSIBLE_HOME yourself.
 */
export declare function binaryPath(tool: Tool, platform?: string, arch?: string): string;
