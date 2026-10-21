// Self-contained HTML dashboard: a single file with no external assets so it
// works as an email/chat attachment, in CI artifacts, or pasted into a wiki.
// Vanilla HTML + scoped CSS + a few lines of JS — no framework, no build step.

const SEVERITY_BADGE = {
  critical: { label: 'CRITICAL', color: '#b91c1c', bg: '#fee2e2' },
  warning:  { label: 'WARNING',  color: '#92400e', bg: '#fef3c7' },
  info:     { label: 'INFO',     color: '#1e40af', bg: '#dbeafe' },
};

const CONFIDENCE_LABEL = {
  'cross-validated': 'Cross-validated · multiple reviewers, independently',
  consensus: 'Consensus · reported by one, validated by another',
  disputed: 'Disputed · reported, then challenged',
  solo: 'Solo · single perspective',
};

const VERDICT_BADGE = {
  approve:     { label: 'approve',     color: '#166534', bg: '#dcfce7' },
  conditional: { label: 'conditional', color: '#854d0e', bg: '#fef9c3' },
  reject:      { label: 'reject',      color: '#991b1b', bg: '#fee2e2' },
  unknown:     { label: '—',           color: '#374151', bg: '#f3f4f6' },
};

function esc(s) {
  return String(s ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

export function renderHtml(syn, { title = 'Adversarial Code Review' } = {}) {
  const crit = syn.findings.filter((f) => f.severity === 'critical').length;
  const warn = syn.findings.filter((f) => f.severity === 'warning').length;
  const info = syn.findings.filter((f) => f.severity === 'info').length;

  const verdictRows = Object.entries(syn.verdicts).map(([persona, verdict]) => {
    const b = VERDICT_BADGE[verdict] ?? VERDICT_BADGE.unknown;
    const summary = esc(syn.summaries[persona] ?? '');
    return `<tr>
      <td class="reviewer">${esc(persona)}</td>
      <td><span class="badge" style="color:${b.color};background:${b.bg}">${esc(b.label)}</span></td>
      <td>${summary}</td>
    </tr>`;
  }).join('\n');

  const groups = { 'cross-validated': [], consensus: [], disputed: [], solo: [] };
  for (const f of syn.findings) groups[f.confidence].push(f);

  const sections = [];
  for (const conf of ['cross-validated', 'consensus', 'disputed', 'solo']) {
    const items = groups[conf];
    if (!items.length) continue;
    sections.push(`
      <section class="findings-group">
        <h2>${esc(CONFIDENCE_LABEL[conf])}</h2>
        ${items.map(renderCard).join('\n')}
      </section>`);
  }

  const degraded = syn.degraded.length
    ? `<div class="banner-warn">Degraded run: <strong>${esc(syn.degraded.join(', '))}</strong> failed and were excluded.</div>`
    : '';

  const noFindings = syn.findings.length === 0
    ? '<section><h2>Findings</h2><p class="empty">No findings. All reviewers reported clean.</p></section>'
    : '';

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>${esc(title)}</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
    :root {
      --fg: #111827; --fg-muted: #4b5563; --bg: #ffffff; --line: #e5e7eb;
      --bg-alt: #f9fafb; --accent: #1d4ed8;
    }
    @media (prefers-color-scheme: dark) {
      :root { --fg: #e5e7eb; --fg-muted: #9ca3af; --bg: #0f172a; --line: #1f2937; --bg-alt: #111827; --accent: #60a5fa; }
    }
    * { box-sizing: border-box; }
    body { margin: 0; padding: 0; background: var(--bg); color: var(--fg);
           font: 14px/1.55 ui-sans-serif, system-ui, -apple-system, sans-serif; }
    .wrap { max-width: 980px; margin: 0 auto; padding: 32px 24px 64px; }
    h1 { font-size: 24px; margin: 0 0 8px; }
    h2 { font-size: 16px; font-weight: 600; margin: 32px 0 12px; color: var(--fg-muted); text-transform: uppercase; letter-spacing: 0.04em; }
    .verdict { font-size: 22px; font-weight: 600; margin: 12px 0; }
    .summary { color: var(--fg-muted); margin: 0 0 24px; }
    table.verdicts { width: 100%; border-collapse: collapse; margin: 0 0 16px; }
    table.verdicts th, table.verdicts td { text-align: left; padding: 8px 12px; border-bottom: 1px solid var(--line); vertical-align: top; }
    table.verdicts th { font-size: 12px; text-transform: uppercase; color: var(--fg-muted); letter-spacing: 0.04em; }
    .reviewer { font-weight: 600; }
    .badge { display: inline-block; font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 999px; text-transform: uppercase; letter-spacing: 0.04em; }
    .banner-warn { background: #fef3c7; color: #92400e; padding: 10px 14px; border-radius: 8px; margin: 16px 0; }
    .empty { color: var(--fg-muted); font-style: italic; }
    details.card { border: 1px solid var(--line); border-radius: 8px; margin: 8px 0; background: var(--bg-alt); }
    details.card[open] { background: var(--bg); }
    details.card summary { padding: 12px 16px; cursor: pointer; list-style: none; display: flex; gap: 12px; align-items: center; }
    details.card summary::-webkit-details-marker { display: none; }
    details.card summary::before { content: '▸'; color: var(--fg-muted); transition: transform .15s; }
    details.card[open] summary::before { transform: rotate(90deg); }
    .card .title { font-weight: 600; flex: 1; }
    .card .loc { font-family: ui-monospace, SFMono-Regular, Consolas, monospace; font-size: 12px; color: var(--fg-muted); }
    .card .body { padding: 0 16px 16px; }
    .card .reporters { font-size: 12px; color: var(--fg-muted); margin: 0 0 8px; }
    .card .detail { margin: 8px 0; }
    .card .fix { background: var(--bg-alt); padding: 8px 12px; border-radius: 6px; margin: 8px 0 0; }
    .card .fix strong { color: var(--accent); }
    blockquote.validate, blockquote.challenge { margin: 6px 0; padding: 6px 12px; border-left: 3px solid; border-radius: 0 6px 6px 0; font-size: 13px; }
    blockquote.validate { border-color: #16a34a; background: rgba(22,163,74,0.08); }
    blockquote.challenge { border-color: #f59e0b; background: rgba(245,158,11,0.08); }
    footer { color: var(--fg-muted); font-size: 12px; margin-top: 48px; border-top: 1px solid var(--line); padding-top: 16px; }
    @media print {
      details.card { break-inside: avoid; }
      details.card summary::before { display: none; }
      details.card > .body { display: block !important; }
    }
  </style>
</head>
<body>
  <main class="wrap">
    <h1>${esc(title)}</h1>
    <div class="verdict">${esc(syn.consensusLabel)}</div>
    <p class="summary">${crit} critical · ${warn} warning · ${info} info — ${syn.findings.length} total across ${Object.keys(syn.verdicts).length} reviewers</p>

    ${degraded}

    <h2>Reviewer verdicts</h2>
    <table class="verdicts">
      <thead><tr><th>Reviewer</th><th>Verdict</th><th>Summary</th></tr></thead>
      <tbody>${verdictRows}</tbody>
    </table>

    ${noFindings}
    ${sections.join('\n')}

    <footer>Generated by adverse — multi-agent adversarial code review.</footer>
  </main>
  <script>
    // Open all expandable cards on '/' or 'e'; collapse all on Escape.
    document.addEventListener('keydown', (e) => {
      if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
      if (e.key === 'e' || e.key === '/') {
        document.querySelectorAll('details.card').forEach(d => d.open = true);
      } else if (e.key === 'Escape') {
        document.querySelectorAll('details.card').forEach(d => d.open = false);
      }
    });
  </script>
</body>
</html>
`;
}

function renderCard(f) {
  const sev = SEVERITY_BADGE[f.severity];
  const loc = f.file ? `${f.file}${f.line !== null ? `:${f.line}` : ''}` : '';
  const validates = (f.validators || []).map((v) =>
    `<blockquote class="validate"><strong>${esc(v.persona)} validates:</strong> ${esc(v.reason)}</blockquote>`,
  ).join('\n');
  const challenges = (f.challengers || []).map((c) =>
    `<blockquote class="challenge"><strong>${esc(c.persona)} challenges:</strong> ${esc(c.reason)}</blockquote>`,
  ).join('\n');
  return `<details class="card">
    <summary>
      <span class="badge" style="color:${sev.color};background:${sev.bg}">${sev.label}</span>
      <span class="title">${esc(f.title)}</span>
      ${loc ? `<span class="loc">${esc(loc)}</span>` : ''}
    </summary>
    <div class="body">
      <p class="reporters">Reported by: ${esc(f.reporters.join(', '))}</p>
      <div class="detail">${esc(f.detail).replaceAll('\n', '<br>')}</div>
      ${f.fix ? `<div class="fix"><strong>Fix:</strong> ${esc(f.fix)}</div>` : ''}
      ${validates}
      ${challenges}
    </div>
  </details>`;
}
