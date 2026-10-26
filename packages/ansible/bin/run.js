'use strict';

// Shared body of the bin shims: runs one tool from the platform package with the caller's arguments.

const { spawnSync } = require('node:child_process');
const { binaryPath } = require('../index.js');

module.exports = function run(tool) {
  let bin;
  try {
    bin = binaryPath(tool);
  } catch (err) {
    console.error(err.message);
    process.exit(1);
  }
  const result = spawnSync(bin, process.argv.slice(2), { stdio: 'inherit' });
  if (result.error) {
    console.error(`@ai-swfactory-oss/ansible: cannot run ${bin}: ${result.error.message}`);
    process.exit(1);
  }
  if (result.signal) {
    process.kill(process.pid, result.signal);
  }
  process.exit(result.status === null ? 1 : result.status);
};
