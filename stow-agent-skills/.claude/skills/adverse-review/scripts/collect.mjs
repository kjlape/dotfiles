#!/usr/bin/env node
// Skill bridge: collect source code into a single text block + file list.
// The same logic powers the standalone CLI (`adverse review`).

import { parseArgs } from 'node:util';
import { writeFileSync } from 'node:fs';
import path from 'node:path';

import { collectDirectory, collectDiff } from '../../../src/collect.mjs';

const { values } = parseArgs({
  options: {
    target:      { type: 'string' },
    diff:        { type: 'string' },
    out:         { type: 'string' },
    'files-out': { type: 'string' },
  },
  strict: true,
});

if (!values.target || !values.out) {
  process.stderr.write('Usage: collect.mjs --target <path> [--diff [base]] --out <file> [--files-out <file>]\n');
  process.exit(2);
}

const target = path.resolve(values.target);
try {
  let block, files;
  if (values.diff !== undefined) {
    const base = values.diff === '' ? null : values.diff;
    ({ block, files } = collectDiff(target, base));
  } else {
    ({ block, files } = collectDirectory(target));
  }
  writeFileSync(values.out, block, 'utf-8');
  if (values['files-out']) writeFileSync(values['files-out'], JSON.stringify(files, null, 2), 'utf-8');
  process.stdout.write(`collected ${files.length} files (${block.length} chars) -> ${values.out}\n`);
} catch (e) {
  process.stderr.write(`collect: ${e.message}\n`);
  process.exit(1);
}
