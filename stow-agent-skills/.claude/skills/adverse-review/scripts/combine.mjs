#!/usr/bin/env node
// Skill bridge: combine N per-persona JSON files into a single keyed-by-persona
// JSON object that the synthesizer accepts.

import { parseArgs } from 'node:util';
import { readFileSync, writeFileSync } from 'node:fs';

const { values, positionals } = parseArgs({
  options: {
    round1: { type: 'string', multiple: true },
    round2: { type: 'string', multiple: true },
    out:    { type: 'string' },
  },
  allowPositionals: true,
  strict: true,
});

if (!values.out) {
  process.stderr.write('Usage: combine.mjs (--round1 a.json b.json …) | (--round2 a.json b.json …) --out <combined.json>\n');
  process.exit(2);
}

const hasRound1 = values.round1 !== undefined;
const hasRound2 = values.round2 !== undefined;
if (hasRound1 === hasRound2) {
  process.stderr.write('combine: provide exactly one of --round1 or --round2\n');
  process.exit(2);
}

const inputs = [...(values.round1 ?? values.round2), ...positionals];

const combined = {};
for (const path of inputs) {
  let payload;
  try {
    payload = JSON.parse(readFileSync(path, 'utf-8'));
  } catch (e) {
    process.stderr.write(`combine: ${path}: ${e.message}\n`);
    process.exit(1);
  }
  if (!payload || typeof payload !== 'object' || Array.isArray(payload) || typeof payload.persona !== 'string') {
    process.stderr.write(`combine: ${path}: missing or invalid \`persona\` field\n`);
    process.exit(1);
  }
  if (combined[payload.persona]) {
    process.stderr.write(`combine: duplicate persona '${payload.persona}' across inputs\n`);
    process.exit(1);
  }
  combined[payload.persona] = payload;
}

writeFileSync(values.out, JSON.stringify(combined, null, 2), 'utf-8');
process.stdout.write(`combined ${inputs.length} reviews -> ${values.out}\n`);
