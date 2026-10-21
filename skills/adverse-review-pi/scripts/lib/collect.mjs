// Collect source code from a target directory or a git diff.

import { execFileSync } from 'node:child_process';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';

export const DEFAULT_MAX_TOTAL_CHARS = 250_000;
export const DEFAULT_MAX_FILE_CHARS = 30_000;

const EXCLUDE_DIRS = new Set([
  '.git', '.hg', '.svn',
  'node_modules', '.venv', 'venv', 'env', '__pycache__',
  'dist', 'build', 'target', 'out', '.next', '.nuxt',
  '.pytest_cache', '.mypy_cache', '.ruff_cache', '.tox',
  'vendor', 'bower_components',
]);

const EXCLUDE_EXTS = new Set([
  '.pyc', '.pyo', '.so', '.dylib', '.dll', '.exe', '.class', '.jar',
  '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ico', '.pdf', '.zip', '.tar',
  '.gz', '.tgz', '.bz2', '.xz', '.7z', '.rar', '.woff', '.woff2', '.ttf',
  '.eot', '.otf', '.mp3', '.mp4', '.wav', '.mov', '.webm', '.webp',
  '.lock',
]);

function isGitRepo(dir) {
  try {
    execFileSync('git', ['-C', dir, 'rev-parse', '--is-inside-work-tree'], {
      stdio: ['ignore', 'pipe', 'pipe'],
      timeout: 5000,
    });
    return true;
  } catch {
    return false;
  }
}

function gitTrackedFiles(dir) {
  const out = execFileSync(
    'git',
    ['-C', dir, 'ls-files', '--cached', '--others', '--exclude-standard'],
    { encoding: 'utf-8', stdio: ['ignore', 'pipe', 'pipe'] },
  );
  return out.split('\n').filter(Boolean).map((rel) => path.join(dir, rel));
}

function walkFiles(root) {
  const files = [];
  const stack = [root];
  while (stack.length) {
    const dir = stack.pop();
    let entries;
    try {
      entries = readdirSync(dir, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const ent of entries) {
      if (ent.isDirectory()) {
        if (!EXCLUDE_DIRS.has(ent.name)) stack.push(path.join(dir, ent.name));
      } else if (ent.isFile()) {
        files.push(path.join(dir, ent.name));
      }
    }
  }
  return files;
}

function looksBinary(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (EXCLUDE_EXTS.has(ext)) return true;
  if (filePath.endsWith('.min.js') || filePath.endsWith('.min.css')) return true;
  try {
    const fd = readFileSync(filePath);
    const head = fd.subarray(0, Math.min(fd.length, 8192));
    for (const b of head) if (b === 0) return true;
  } catch {
    return true;
  }
  return false;
}

export function collectDirectory(
  target,
  { maxTotalChars = DEFAULT_MAX_TOTAL_CHARS, maxFileChars = DEFAULT_MAX_FILE_CHARS } = {},
) {
  const absRoot = path.resolve(target);
  const candidates = (isGitRepo(absRoot) ? gitTrackedFiles(absRoot) : walkFiles(absRoot)).sort();

  const parts = [];
  const included = [];
  let total = 0;

  for (const filePath of candidates) {
    let st;
    try {
      st = statSync(filePath);
    } catch {
      continue;
    }
    if (!st.isFile()) continue;
    if (looksBinary(filePath)) continue;
    let text;
    try {
      text = readFileSync(filePath, { encoding: 'utf-8' });
    } catch {
      continue;
    }
    if (!text.trim()) continue;
    let truncated = false;
    if (text.length > maxFileChars) {
      text = text.slice(0, maxFileChars);
      truncated = true;
    }
    const rel = path.relative(absRoot, filePath).split(path.sep).join('/');
    let header = `\n=== FILE: ${rel}`;
    if (truncated) header += ` (truncated to ${maxFileChars} chars)`;
    header += ' ===\n';
    const block = header + text + '\n';
    if (total + block.length > maxTotalChars) {
      parts.push(
        `\n=== TRUNCATED: ${candidates.length - included.length} more files omitted ` +
          `after ${maxTotalChars}-char budget reached ===\n`,
      );
      break;
    }
    parts.push(block);
    included.push(rel);
    total += block.length;
  }

  if (!included.length) {
    throw new Error(`no reviewable source files found under ${absRoot}`);
  }
  return { block: parts.join(''), files: included };
}

export function collectDiff(target, base) {
  const absRoot = path.resolve(target);
  if (!isGitRepo(absRoot)) {
    throw new Error(`${absRoot} is not a git repository (--diff requires git)`);
  }
  const diffArgs = base ? ['diff', `${base}...HEAD`] : ['diff', 'HEAD'];
  const namesArgs = base ? ['diff', '--name-only', `${base}...HEAD`] : ['diff', '--name-only', 'HEAD'];

  const diff = execFileSync('git', ['-C', absRoot, ...diffArgs], {
    encoding: 'utf-8',
    stdio: ['ignore', 'pipe', 'pipe'],
    maxBuffer: 50 * 1024 * 1024,
  });
  const names = execFileSync('git', ['-C', absRoot, ...namesArgs], {
    encoding: 'utf-8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  const files = names.split('\n').filter(Boolean);
  if (!diff.trim()) throw new Error('no changes to review (git diff was empty)');

  let truncated = diff;
  if (truncated.length > DEFAULT_MAX_TOTAL_CHARS) {
    truncated = truncated.slice(0, DEFAULT_MAX_TOTAL_CHARS) + '\n... (diff truncated to fit context budget) ...\n';
  }
  const block =
    'The following is a unified git diff. Review the *changes*, not the surrounding code.\n\n```diff\n' +
    truncated +
    '\n```\n';
  return { block, files };
}
