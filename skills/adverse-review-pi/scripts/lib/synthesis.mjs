// Deterministic synthesis: turn 3 round-1 reviews + 3 round-2 cross-reviews
// into a single ranked report.
//
// Why deterministic (not another LLM call): a fourth model invocation costs
// more, adds another failure mode, and would itself be subject to the same
// single-model bias the personas have. Cross-validation BETWEEN personas is
// the signal — we just count and present it.
//
// Confidence taxonomy:
//  - cross-validated : reported by ≥2 personas (no explicit cross-review needed)
//  - consensus       : reported by ≥1 persona AND validated by ≥1 other in round 2
//  - disputed        : reported by ≥1 persona AND challenged by ≥1 other
//  - solo            : reported by exactly 1 persona, no validate, no challenge
//
// A finding can be both `consensus` (one validates) and `disputed` (another
// challenges) — we mark it `disputed` because the dispute is the more
// interesting signal to a human reader.

const SEVERITY_ORDER = { critical: 0, warning: 1, info: 2 };
// Verdict → score mapping. The natural symmetric choice: approve and reject
// cancel each other out, conditional carries half-weight on the approve side.
// The mean across reviewers gives the final score in [-1, 1].
const verdictScores = { approve: 1, conditional: 0.5, reject: -1 };
const CONFIDENCE_RANK = { disputed: 0, 'cross-validated': 1, consensus: 2, solo: 3 };

function severityRank(s) {
  return SEVERITY_ORDER[s] ?? 99;
}

function normTitle(t) {
  return t.toLowerCase().split(/\s+/).join(' ').replace(/[.:,;!?]+$/, '');
}

function coerceInt(v) {
  if (typeof v === 'number' && Number.isInteger(v)) return v;
  if (typeof v === 'string') {
    const n = parseInt(v, 10);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

function coerceStr(v) {
  return typeof v === 'string' && v.trim() ? v : null;
}

function buildFinding(persona, raw) {
  const title = coerceStr(raw?.title);
  const severity = raw?.severity;
  if (!title || !(severity in SEVERITY_ORDER)) return null;
  return {
    severity,
    title: title.trim(),
    detail: (coerceStr(raw?.detail) ?? '').trim(),
    file: coerceStr(raw?.file),
    line: coerceInt(raw?.line),
    fix: coerceStr(raw?.fix),
    reporters: [persona],
    validators: [], // Array<{persona, reason}>
    challengers: [],
    confidence: 'solo',
  };
}

export function synthesize(round1, round2 = {}, { failedPersonas = [] } = {}) {
  const byKey = new Map(); // `${normTitle}|${file}|${line}` -> Finding
  const byNormTitle = new Map(); // normTitle -> Finding (fallback join key)

  function upsert(persona, raw) {
    const f = buildFinding(persona, raw);
    if (f === null) return null;
    const norm = normTitle(f.title);
    const primaryKey = `${norm}|${f.file ?? ''}|${f.line ?? ''}`;
    let existing = byKey.get(primaryKey) ?? byNormTitle.get(norm);
    if (existing) {
      if (!existing.reporters.includes(persona)) existing.reporters.push(persona);
      if (severityRank(f.severity) < severityRank(existing.severity)) {
        existing.severity = f.severity;
      }
      if (f.detail.length > existing.detail.length) existing.detail = f.detail;
      if (!existing.fix && f.fix) existing.fix = f.fix;
      if (existing.file === null && f.file) existing.file = f.file;
      if (existing.line === null && f.line !== null) existing.line = f.line;
      return existing;
    }
    byKey.set(primaryKey, f);
    byNormTitle.set(norm, f);
    return f;
  }

  // 1. Phase 1 findings
  for (const [persona, review] of Object.entries(round1)) {
    for (const raw of review?.findings ?? []) {
      if (raw && typeof raw === 'object') upsert(persona, raw);
    }
  }

  // 2. Phase 2 "added" findings (treated as first-class)
  for (const [persona, cross] of Object.entries(round2)) {
    for (const raw of cross?.added ?? []) {
      if (raw && typeof raw === 'object') upsert(persona, raw);
    }
  }

  // 3. Phase 2 validates / challenges
  function findByTitle(title) {
    if (typeof title !== 'string') return null;
    return byNormTitle.get(normTitle(title)) ?? null;
  }

  for (const [persona, cross] of Object.entries(round2)) {
    for (const v of cross?.validate ?? []) {
      if (!v || typeof v !== 'object') continue;
      const f = findByTitle(v.title);
      if (!f || f.reporters.includes(persona)) continue; // self-validation does not count
      const reason = (coerceStr(v.reason) ?? '').trim();
      f.validators.push({ persona, reason });
    }
    for (const c of cross?.challenge ?? []) {
      if (!c || typeof c !== 'object') continue;
      const f = findByTitle(c.title);
      if (!f || f.reporters.includes(persona)) continue;
      const reason = (coerceStr(c.reason) ?? '').trim();
      f.challengers.push({ persona, reason });
    }
  }

  // 4. Confidence labels
  for (const f of byKey.values()) {
    if (f.challengers.length > 0) f.confidence = 'disputed';
    else if (f.reporters.length >= 2) f.confidence = 'cross-validated';
    else if (f.validators.length > 0) f.confidence = 'consensus';
    else f.confidence = 'solo';
  }

  const findings = [...byKey.values()].sort((a, b) => {
    const s = severityRank(a.severity) - severityRank(b.severity);
    if (s !== 0) return s;
    const c = CONFIDENCE_RANK[a.confidence] - CONFIDENCE_RANK[b.confidence];
    if (c !== 0) return c;
    return a.title.toLowerCase().localeCompare(b.title.toLowerCase());
  });

  // 5. Verdicts and consensus label
  const verdicts = {};
  const summaries = {};
  for (const [p, r] of Object.entries(round1)) {
    verdicts[p] = r?.verdict ?? 'unknown';
    summaries[p] = String(r?.summary ?? '').slice(0, 300);
  }
  const verdictList = Object.values(verdicts);
  const score =
    verdictList.length > 0
      ? verdictList.reduce((acc, v) => acc + (verdictScores[v] ?? 0), 0) / verdictList.length
      : 0;
  const label = consensusLabel(score, verdictList);

  return {
    findings,
    verdicts,
    summaries,
    consensusLabel: label,
    consensusScore: score,
    degraded: [...failedPersonas],
  };
}

// Map (score, verdict mix) → a one-line label for the report banner. The
// labels use standard ship/hold/block vocabulary; the n/k suffix shows how
// many reviewers fell on the "ship" side vs. the total.
function consensusLabel(score, verdicts) {
  const total = verdicts.length;
  const ships = verdicts.filter((v) => v === 'approve' || v === 'conditional').length;
  const blocks = verdicts.filter((v) => v === 'reject').length;
  const hasConditional = verdicts.includes('conditional');

  if (score === 1) return `SHIP (unanimous, ${ships}/${total})`;
  if (score === -1) return `BLOCK (unanimous, ${blocks}/${total})`;
  if (score === 0) return `HOLD — split decision (${ships}/${total} ship, ${blocks}/${total} block)`;
  if (score > 0) {
    const kind = hasConditional ? 'SHIP-WITH-CAVEATS' : 'SHIP';
    return `${kind} (${ships}/${total} ship, ${blocks}/${total} block)`;
  }
  return `BLOCK (${blocks}/${total} block, ${ships}/${total} ship)`;
}

// ---------- Markdown renderer -----------------------------------------------

const SEVERITY_MARKER = { critical: '🔴', warning: '🟡', info: '🔵' };

const SECTION_TITLES = {
  'cross-validated': '## Cross-validated findings (multiple reviewers reported independently)',
  consensus: '## Consensus findings (reported by one, validated by another)',
  disputed: '## Disputed findings (reported, then challenged)',
  solo: '## Single-reviewer findings (one perspective only)',
};

export function renderMarkdown(syn, { title = 'Adversarial Code Review' } = {}) {
  const lines = [];
  lines.push(`# ${title}`);
  lines.push('');

  const crit = syn.findings.filter((f) => f.severity === 'critical').length;
  const warn = syn.findings.filter((f) => f.severity === 'warning').length;
  const info = syn.findings.filter((f) => f.severity === 'info').length;
  lines.push(`**Verdict:** ${syn.consensusLabel}  `);
  lines.push(
    `**Findings:** ${crit} critical · ${warn} warning · ${info} info ` +
      `(${syn.findings.length} total across ${Object.keys(syn.verdicts).length} reviewers)`,
  );
  lines.push('');

  lines.push('## Reviewer verdicts');
  lines.push('');
  lines.push('| Reviewer | Verdict | Summary |');
  lines.push('|---|---|---|');
  for (const [p, v] of Object.entries(syn.verdicts)) {
    const summary = (syn.summaries[p] ?? '').replaceAll('|', '\\|');
    lines.push(`| ${p} | ${v} | ${summary} |`);
  }
  if (syn.degraded.length) {
    lines.push('');
    lines.push(
      `> **Degraded run:** the following reviewers failed and were excluded: ${syn.degraded.join(', ')}.`,
    );
  }
  lines.push('');

  if (syn.findings.length === 0) {
    lines.push('## Findings');
    lines.push('');
    lines.push('_No findings. All reviewers reported clean._');
    lines.push('');
    return lines.join('\n');
  }

  const groups = { 'cross-validated': [], consensus: [], disputed: [], solo: [] };
  for (const f of syn.findings) groups[f.confidence].push(f);

  for (const conf of ['cross-validated', 'consensus', 'disputed', 'solo']) {
    const items = groups[conf];
    if (!items.length) continue;
    lines.push(SECTION_TITLES[conf]);
    lines.push('');
    for (const f of items) {
      lines.push(...renderFinding(f));
      lines.push('');
    }
  }

  return lines.join('\n').trimEnd() + '\n';
}

function renderFinding(f) {
  const marker = SEVERITY_MARKER[f.severity] ?? '·';
  let loc = '';
  if (f.file) {
    loc = ` — \`${f.file}`;
    if (f.line !== null) loc += `:${f.line}`;
    loc += '`';
  }
  const out = [`### ${marker} **[${f.severity.toUpperCase()}]** ${f.title}${loc}`];
  out.push('');
  out.push(`_Reported by: ${f.reporters.join(', ')}_`);
  out.push('');
  out.push(f.detail);
  if (f.fix) {
    out.push('');
    out.push(`**Fix:** ${f.fix}`);
  }
  if (f.validators.length) {
    out.push('');
    for (const { persona, reason } of f.validators) {
      out.push(`> ✅ **${persona} validates:** ${reason}`);
    }
  }
  if (f.challengers.length) {
    out.push('');
    for (const { persona, reason } of f.challengers) {
      out.push(`> ⚠️ **${persona} challenges:** ${reason}`);
    }
  }
  return out;
}

// ---------- JSON serializer (for --json-out and Skill bridge) ---------------

export function toJsonReport(syn) {
  return {
    consensus_label: syn.consensusLabel,
    consensus_score: syn.consensusScore,
    verdicts: syn.verdicts,
    summaries: syn.summaries,
    degraded: syn.degraded,
    findings: syn.findings.map((f) => ({
      severity: f.severity,
      title: f.title,
      detail: f.detail,
      file: f.file,
      line: f.line,
      fix: f.fix,
      reporters: f.reporters,
      validators: f.validators,
      challengers: f.challengers,
      confidence: f.confidence,
    })),
  };
}
