#!/usr/bin/env node
/**
 * build-manual-html-fixed.mjs (v2.2.0)
 * Complete rewrite fixing all known issues:
 * - Content rendering (tables, code blocks, blockquotes)
 * - Navigation links (internal anchors)
 * - Search functionality
 * - Sidebar grouping
 * - Page-level TOC
 * - Mobile responsiveness
 * - Accessibility
 * - Syntax highlighting
 *
 * Usage:
 *   node build-manual-html-fixed.mjs            # generate
 *   node build-manual-html-fixed.mjs --check    # validate (for CI)
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const UM = __dirname;
const OUT = path.join(UM, 'manual.html');
const HASH_FILE = path.join(UM, '.manual.hash');

const ORDER = [
  'README.md', 'INDEX.md', 'System_Overview.md', 'Prerequisites.md',
  'Getting_Started.md', 'CANONICAL_REPO_AND_INTERFACES.md', 'Happy_Path_End_to_End.md',
  'SDLC_Flows.md', 'Role_and_Stage_Playbook.md', 'FEATURES_REFERENCE.md', 'Commands.md',
  'Guided_Execution_and_Recovery.md', 'Persistent_Memory.md', 'ADO_MCP_Integration.md',
  'Agents_Skills_Rules.md', 'Architecture.md', '../docs/sdlc-stage-role-mapping.md',
  'Token_Efficiency_and_Context_Loading.md', 'Repository_Complexity_Explained.md',
  'PR_Merge_Process.md', 'Enforcement_Contract.md', 'Traceability_and_Governance.md',
  'Platform_Extension_Onboarding.md', 'Team_Onboarding_Presentation.md',
  'Documentation_Rules.md', 'FAQ.md', 'CHANGELOG.md'
];

const GROUPS = {
  '📍 Getting Started': ['README.md', 'INDEX.md', 'Prerequisites.md', 'Getting_Started.md'],
  '🎯 Concepts & Architecture': ['System_Overview.md', 'Architecture.md', 'CANONICAL_REPO_AND_INTERFACES.md'],
  '🛠️ Workflows & Execution': ['SDLC_Flows.md', 'Happy_Path_End_to_End.md', 'Role_and_Stage_Playbook.md', 'Commands.md', 'Guided_Execution_and_Recovery.md'],
  '✨ Features': ['FEATURES_REFERENCE.md', 'Persistent_Memory.md', 'ADO_MCP_Integration.md', 'Token_Efficiency_and_Context_Loading.md'],
  '📖 Deep Dives': ['Agents_Skills_Rules.md', 'Repository_Complexity_Explained.md', '../docs/sdlc-stage-role-mapping.md'],
  '🔒 Quality & Governance': ['PR_Merge_Process.md', 'Enforcement_Contract.md', 'Traceability_and_Governance.md'],
  '🔧 Advanced': ['Platform_Extension_Onboarding.md', 'Team_Onboarding_Presentation.md', 'Documentation_Rules.md'],
  '📚 Reference': ['FAQ.md', 'CHANGELOG.md']
};

const TITLES = {
  'README.md': '🏠 Home', 'INDEX.md': '📚 Index & Guide', 'FEATURES_REFERENCE.md': '✨ Features',
  'ADO_MCP_Integration.md': '🔗 ADO & MCP', 'PR_Merge_Process.md': '🔄 PR & Merge',
  'SDLC_Flows.md': '🌊 SDLC Flows', 'CANONICAL_REPO_AND_INTERFACES.md': '🏗️ Canonical Repo',
  'FAQ.md': '❓ FAQ', 'CHANGELOG.md': '📝 Changelog'
};

function titleFor(name) {
  return TITLES[name] || name.replace(/\.md$/, '').replace(/_/g, ' ');
}

function slugFor(name) {
  return name.replace(/\.md$/, '').replace(/^.*[\\/]/, '').toLowerCase();
}

function esc(s) {
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function loadDocs() {
  const docs = [];
  const missing = [];
  for (const f of ORDER) {
    const p = path.join(UM, f);
    if (!fs.existsSync(p)) {
      missing.push(f);
      continue;
    }
    const markdown = fs.readFileSync(p, 'utf8');
    docs.push({ file: f, slug: slugFor(f), title: titleFor(f), markdown });
  }
  if (missing.length > 0) console.warn(`⚠️  Skipped: ${missing.join(', ')}`);
  return { docs, missing };
}

function generateTOC(markdown) {
  const headings = [];
  for (const line of markdown.split('\n')) {
    const m2 = line.match(/^## (.+)$/);
    const m3 = line.match(/^### (.+)$/);
    if (m2) {
      const id = m2[1].toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
      headings.push({ level: 2, text: m2[1], id });
    } else if (m3) {
      const id = m3[1].toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
      headings.push({ level: 3, text: m3[1], id });
    }
  }
  if (headings.length === 0) return '';
  let toc = '<div class="page-toc"><details><summary>📑 Jump to section</summary><ul>';
  for (const h of headings) {
    const indent = h.level === 3 ? '  ' : '';
    toc += `${indent}<li><a href="#${h.id}">${h.text}</a></li>`;
  }
  return toc + '</ul></details></div>';
}

function markdownToHtml(md) {
  let html = md;
  const parts = { code: {}, table: {}, blockquote: {} };
  let codeIdx = 0, tableIdx = 0, blockquoteIdx = 0;

  // Extract code blocks with language
  html = html.replace(/```([\w-]*)\n([\s\S]*?)```/g, (match, lang, code) => {
    const id = `__CODE_${codeIdx}__`;
    const language = lang.trim() || 'bash';
    parts.code[codeIdx] = `<pre><code class="language-${esc(language)}">${esc(code)}</code></pre>`;
    codeIdx++;
    return id;
  });

  // Extract tables
  html = html.replace(/\n(\|[^\n]+\n)+/g, (match) => {
    const id = `__TABLE_${tableIdx}__`;
    const rows = match.trim().split('\n').filter(r => r.trim());
    let isHeader = true;
    let table = '<table>\n';
    for (const row of rows) {
      const cells = row.split('|').filter(c => c.trim()).map(c => c.trim());
      if (cells.every(c => /^[:\s-]+$/.test(c))) continue;
      const tag = isHeader ? 'th' : 'td';
      table += '<tr>' + cells.map(c => `<${tag}>${c}</${tag}>`).join('') + '</tr>\n';
      if (isHeader) isHeader = false;
    }
    table += '</table>';
    parts.table[tableIdx] = table;
    tableIdx++;
    return id;
  });

  // Extract blockquotes
  html = html.replace(/^> (.+)$/gm, (match, content) => {
    const id = `__BLOCKQUOTE_${blockquoteIdx}__`;
    parts.blockquote[blockquoteIdx] = `<blockquote>${content}</blockquote>`;
    blockquoteIdx++;
    return id;
  });

  // Headings with IDs
  html = html.replace(/^### (.+)$/gm, (match, text) => {
    const id = text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
    return `<h3 id="${id}">${text}</h3>`;
  });
  html = html.replace(/^## (.+)$/gm, (match, text) => {
    const id = text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
    return `<h2 id="${id}">${text}</h2>`;
  });
  html = html.replace(/^# (.+)$/gm, '<h1>$1</h1>');

  // Lists
  html = html.replace(/^[\s]*[-*+] (.+)$/gm, '<li>$1</li>');
  html = html.replace(/(<li>[\s\S]*?<\/li>)/g, '<ul>\n$1\n</ul>');

  // Inline formatting
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
  html = html.replace(/__(.+?)__/g, '<strong>$1</strong>');
  html = html.replace(/\*(.+?)\*/g, '<em>$1</em>');
  html = html.replace(/_(.+?)_/g, '<em>$1</em>');
  html = html.replace(/`([^`]+)`/g, '<code>$1</code>');

  // Links - FIX: Convert markdown links to anchors
  html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (match, text, href) => {
    if (href.endsWith('.md') || href.includes('.md#')) {
      const slug = href.replace(/\.md.*$/, '').replace(/^.*[\\/]/, '').toLowerCase();
      return `<a href="#${slug}">${text}</a>`;
    }
    return `<a href="${href}">${text}</a>`;
  });

  // Horizontal rules
  html = html.replace(/^[-*_]{3,}$/gm, '<hr />');

  // Paragraphs
  html = html.split('\n\n').map(para => {
    para = para.trim();
    if (!para || para.startsWith('<') || para.startsWith('__')) return para;
    if (para.match(/^<(h|ul|ol|table|blockquote|pre|hr)/)) return para;
    return `<p>${para}</p>`;
  }).join('\n');

  // Restore in order
  for (let i = 0; i < codeIdx; i++) if (parts.code[i]) html = html.replace(`__CODE_${i}__`, parts.code[i]);
  for (let i = 0; i < tableIdx; i++) if (parts.table[i]) html = html.replace(`__TABLE_${i}__`, parts.table[i]);
  for (let i = 0; i < blockquoteIdx; i++) if (parts.blockquote[i]) html = html.replace(`__BLOCKQUOTE_${i}__`, parts.blockquote[i]);

  return html;
}

function buildSidebarNav(docs) {
  const docsByFile = Object.fromEntries(docs.map(d => [d.file, d]));
  let nav = '';

  for (const [groupName, files] of Object.entries(GROUPS)) {
    const groupDocs = files.filter(f => docsByFile[f]).map(f => docsByFile[f]);
    if (groupDocs.length === 0) continue;

    nav += `    <fieldset class="nav-group">\n      <legend>${groupName}</legend>\n      <ul>\n`;
    for (const doc of groupDocs) {
      nav += `        <li><a href="#${doc.slug}" class="nav-link">${doc.title}</a></li>\n`;
    }
    nav += `      </ul>\n    </fieldset>\n`;
  }
  return nav;
}

function buildHTML(docs) {
  const navItems = buildSidebarNav(docs);
  const docCards = docs.map(d => {
    const toc = generateTOC(d.markdown);
    const htmlContent = markdownToHtml(d.markdown);
    return `    <article id="${d.slug}" class="doc-card">\n      <div class="doc-header"><h1>${esc(d.title)}</h1>${toc}</div>\n      <div class="doc-content markdown-body">${htmlContent}</div>\n    </article>\n`;
  }).join('\n');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="AI-SDLC Platform — Complete offline manual (v2.2.0)" />
  <title>AI-SDLC Platform · Manual v2.2.0</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-light.min.css" />
  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"><\/script>
  <style>
:root {
  --bg-primary: #ffffff;
  --bg-secondary: #f5f5f7;
  --bg-tertiary: #efefef;
  --text-primary: #1d1d1d;
  --text-secondary: #666666;
  --text-tertiary: #999999;
  --accent: #0071e3;
  --accent-hover: #0077ed;
  --border: #e5e5e7;
  --radius: 12px;
  --font: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg-primary: #1d1d1f;
    --bg-secondary: #2a2a2e;
    --bg-tertiary: #424245;
    --text-primary: #f5f5f7;
    --text-secondary: #a1a1a6;
    --text-tertiary: #727278;
    --border: #424245;
  }
}

* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body { margin: 0; font-family: var(--font); background: var(--bg-primary); color: var(--text-primary); line-height: 1.6; }

.app-container { display: grid; grid-template-columns: 280px 1fr; max-width: 1400px; margin: 0 auto; min-height: 100vh; }

.sidebar { position: sticky; top: 0; height: 100vh; overflow-y: auto; padding: 24px 0; border-right: 1px solid var(--border); background: var(--bg-secondary); }

.sidebar-header { padding: 0 20px 24px; border-bottom: 1px solid var(--border); margin-bottom: 24px; }

.sidebar-title { font-size: 14px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; color: var(--text-tertiary); }

.search-box { padding: 0 20px 20px; }

.search-input { width: 100%; padding: 8px 12px; border: 1px solid var(--border); border-radius: var(--radius); background: var(--bg-primary); color: var(--text-primary); font-size: 14px; font-family: var(--font); }

.search-input::placeholder { color: var(--text-tertiary); }

.nav-group { margin: 0; border: none; padding: 0 0 20px 0; margin-bottom: 20px; border-bottom: 1px solid var(--border); }

.nav-group:last-child { border-bottom: none; }

.nav-group legend { font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; color: var(--text-tertiary); padding: 0 20px 12px 20px; margin: 0; }

.nav-group ul { list-style: none; padding: 0; margin: 0; }

.nav-link { display: block; padding: 10px 20px; color: var(--text-secondary); text-decoration: none; font-size: 14px; border-left: 3px solid transparent; transition: all 0.2s cubic-bezier(0.25, 0.1, 0.25, 1); }

.nav-link:hover { color: var(--text-primary); background: var(--bg-tertiary); }

.nav-link.active { color: var(--accent); border-left-color: var(--accent); background: var(--bg-primary); }

.main-content { padding: 40px 60px; overflow-y: auto; max-height: 100vh; }

.doc-card { margin-bottom: 80px; scroll-margin-top: 100px; }

.doc-header h1 { font-size: 32px; font-weight: 700; margin: 0 0 12px 0; line-height: 1.2; }

.page-toc { margin: 20px 0; padding: 12px 16px; background: var(--bg-secondary); border: 1px solid var(--border); border-radius: var(--radius); }

.page-toc summary { cursor: pointer; font-weight: 600; color: var(--accent); }

.page-toc ul { margin: 12px 0 0 0; padding-left: 20px; list-style: none; }

.page-toc li { margin: 6px 0; }

.page-toc a { color: var(--text-secondary); text-decoration: none; font-size: 14px; }

.page-toc a:hover { color: var(--accent); }

.doc-content { font-size: 16px; }

.doc-content h2 { font-size: 24px; font-weight: 600; margin: 36px 0 16px 0; padding-top: 20px; border-top: 1px solid var(--border); }

.doc-content h3 { font-size: 18px; font-weight: 600; margin: 24px 0 12px 0; }

.doc-content p { margin: 16px 0; }

.doc-content a { color: var(--accent); text-decoration: none; font-weight: 500; }

.doc-content a:hover { text-decoration: underline; }

.doc-content code { background: var(--bg-secondary); padding: 2px 6px; border-radius: 4px; font-family: 'Menlo', 'Monaco', monospace; font-size: 14px; }

.doc-content pre { background: var(--bg-tertiary); padding: 16px; border-radius: var(--radius); overflow-x: auto; border: 1px solid var(--border); margin: 16px 0; }

.doc-content pre code { background: none; padding: 0; font-size: 13px; line-height: 1.5; }

.hljs { background: transparent !important; }

.doc-content table { border-collapse: collapse; width: 100%; margin: 16px 0; border: 1px solid var(--border); }

.doc-content th { background: var(--bg-secondary); padding: 12px; text-align: left; font-weight: 600; border: 1px solid var(--border); }

.doc-content td { padding: 12px; border: 1px solid var(--border); }

.doc-content ul, .doc-content ol { margin: 16px 0; padding-left: 24px; }

.doc-content li { margin: 8px 0; }

.doc-content blockquote { margin: 16px 0; padding: 12px 16px; border-left: 3px solid var(--accent); background: var(--bg-secondary); border-radius: 4px; }

.doc-content hr { margin: 20px 0; border: none; border-top: 1px solid var(--border); }

@media (max-width: 768px) {
  .app-container { grid-template-columns: 1fr; }
  .sidebar { position: relative; height: auto; max-height: 50vh; border-right: none; border-bottom: 1px solid var(--border); }
  .main-content { padding: 24px; }
  .doc-header h1 { font-size: 24px; }
}

::-webkit-scrollbar { width: 8px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: var(--text-tertiary); border-radius: 4px; }
::-webkit-scrollbar-thumb:hover { background: var(--text-secondary); }

.skip-to-main { position: absolute; top: -40px; left: 0; background: var(--accent); color: white; padding: 8px; text-decoration: none; z-index: 100; }
.skip-to-main:focus { top: 0; }
  </style>
</head>
<body>
  <a href="#main-content" class="skip-to-main">Skip to main content</a>
  <div class="app-container">
    <aside class="sidebar" role="navigation" aria-label="Main navigation">
      <div class="sidebar-header"><h2 class="sidebar-title">📚 Manual</h2></div>
      <div class="search-box">
        <input type="text" class="search-input" id="searchInput" placeholder="🔍 Search..." aria-label="Search documentation" />
      </div>
      <nav class="sidebar-nav" id="navContainer">
${navItems}
      </nav>
    </aside>
    <main class="main-content" id="main-content" role="main">
${docCards}
    </main>
  </div>
  <script>
    document.addEventListener('DOMContentLoaded', function() {
      document.querySelectorAll('pre code').forEach((block) => hljs.highlightElement(block));
    });

    const searchInput = document.getElementById('searchInput');
    const navLinks = document.querySelectorAll('.nav-link');
    const docCards = document.querySelectorAll('.doc-card');

    searchInput.addEventListener('input', (e) => {
      const query = e.target.value.toLowerCase().trim();
      if (!query) {
        docCards.forEach(card => card.style.display = 'block');
        navLinks.forEach(link => link.style.opacity = '1');
        return;
      }
      const words = query.split(/\\s+/);
      docCards.forEach(card => {
        const matches = words.every(w => card.textContent.toLowerCase().includes(w));
        card.style.display = matches ? 'block' : 'none';
      });
      navLinks.forEach(link => {
        const slug = link.getAttribute('href').substring(1);
        const card = document.getElementById(slug);
        link.style.opacity = (card && card.style.display !== 'none') ? '1' : '0.5';
      });
    });

    function updateActiveLink() {
      for (const card of docCards) {
        const rect = card.getBoundingClientRect();
        if (rect.top <= 150 && rect.bottom > 150) {
          navLinks.forEach(l => l.classList.remove('active'));
          const link = document.querySelector('a[href="#' + card.id + '"]');
          if (link) link.classList.add('active');
          break;
        }
      }
    }

    window.addEventListener('scroll', updateActiveLink);
    updateActiveLink();

    document.addEventListener('keydown', e => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        searchInput.focus();
      }
    });
  </script>
</body>
</html>`;
}

function computeHash(html) {
  return crypto.createHash('sha256').update(html).digest('hex');
}

function main() {
  const { docs } = loadDocs();
  const html = buildHTML(docs);
  fs.writeFileSync(OUT, html, 'utf8');
  const hash = computeHash(html);
  fs.writeFileSync(HASH_FILE, hash, 'utf8');
  console.log(`✓ Generated manual.html (v2.2.0, ${docs.length} sections, ${(html.length/1024).toFixed(1)} KB)`);
}

function check() {
  const { docs } = loadDocs();
  const html = buildHTML(docs);
  const currentHash = computeHash(html);
  if (!fs.existsSync(HASH_FILE)) {
    console.error('✗ manual.html stale. Run: node User_Manual/build-manual-html.mjs');
    process.exit(1);
  }
  if (currentHash !== fs.readFileSync(HASH_FILE, 'utf8').trim()) {
    console.error('✗ manual.html stale. Run: node User_Manual/build-manual-html.mjs');
    process.exit(1);
  }
  console.log('✓ manual.html is current');
}

process.argv.includes('--check') ? check() : main();
