#!/usr/bin/env node
// One-time script: regenerates the prompt text files under prompts/ from the
// canonical persona definitions in src/personas.mjs and src/prompts.mjs.
// Run after editing those files to keep the Skill prompts in sync. The CLI
// reads the canonical definitions directly; only the Skill needs file copies.

import { writeFileSync, mkdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { PERSONAS } from '../../../src/personas.mjs';
import { PHASE1_INSTRUCTIONS, PHASE2_INSTRUCTIONS } from '../../../src/prompts.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.join(here, 'prompts');
mkdirSync(outDir, { recursive: true });

for (const p of Object.values(PERSONAS)) {
  writeFileSync(path.join(outDir, `${p.name}.txt`), p.system + '\n', 'utf-8');
}
writeFileSync(path.join(outDir, 'round1.txt'), PHASE1_INSTRUCTIONS, 'utf-8');
writeFileSync(path.join(outDir, 'round2.txt'), PHASE2_INSTRUCTIONS, 'utf-8');

process.stdout.write(`wrote ${Object.keys(PERSONAS).length + 2} prompt files to ${outDir}\n`);
