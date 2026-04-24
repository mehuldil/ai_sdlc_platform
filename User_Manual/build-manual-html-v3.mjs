#!/usr/bin/env node
/**
 * build-manual-html-v3.mjs
 * Apple-inspired design with improved navigation and UX
 *
 * Usage:
 *   node build-manual-html-v3.mjs            # generate manual.html
 *   node build-manual-html-v3.mjs --check    # check if manual is current
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const UM = __dirname;
const OUT = path.join(UM, 'manual.html');

// Documentation reading order
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

const TITLES = {
  'README.md': '🏠 Home',
  'INDEX.md': '📚 Index & Reading Guide',
  'FEATURES_REFERENCE.md': '✨ Features — How They Work',
  'ADO_MCP_Integration.md': '🔗 ADO & MCP Integration',
  'PR_Merge_Process.md': '🔄 PR & Merge Process',
  'SDLC_Flows.md': '🌊 SDLC Flows',
  'CANONICAL_REPO_AND_INTERFACES.md': '🏗️ Canonical Repo & Interfaces',
  'FAQ.md': '❓ FAQ & Troubleshooting',
  'CHANGELOG.md': '📝 Changelog',
};

function titleFor(name) {
  if (TITLES[name]) return TITLES[name];
  return name.replace(/\.md$/, '').replace(/_/g, ' ');
}

function slugFor(name) {
  return name.replace(/\.md$/, '').replace(/^.*[\\/]/, '').toLowerCase();
}

function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
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
    docs.push({
      file: f,
      slug: slugFor(f),
      title: titleFor(f),
      markdown: markdown,
    });
  }
  if (missing.length > 0) {
    console.warn(`⚠️  Skipped (not found): ${missing.join(', ')}`);
  }
  return { docs, missing };
}

function buildHTML(docs) {
  const docsBySlug = Object.fromEntries(docs.map(d => [d.slug, d.markdown]));

  // Build sidebar navigation with categories
  const navItems = docs.map(d =>
    `<li><a href="#${d.slug}" class="nav-link">${d.title}</a></li>`
  ).join('\n');

  // Build doc cards
  const docCards = docs.map(d => `
    <article id="${d.slug}" class="doc-card">
      <div class="doc-header">
        <h1>${esc(d.title)}</h1>
      </div>
      <div class="doc-content markdown-body">${markdownToHtml(d.markdown)}</div>
    </article>
  `).join('\n');

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="AI-SDLC Platform — Complete offline user manual (v2.1.4)" />
  <meta name="theme-color" content="#ffffff" />
  <title>AI-SDLC Platform · User Manual v2.1.4</title>
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
      --radius-sm: 8px;
      --radius-md: 12px;
      --radius-lg: 16px;
      --shadow-sm: 0 1px 3px rgba(0,0,0,0.08);
      --shadow-md: 0 4px 12px rgba(0,0,0,0.12);
      --ease: cubic-bezier(0.25, 0.1, 0.25, 1);
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
    body {
      margin: 0;
      font-family: var(--font);
      background: var(--bg-primary);
      color: var(--text-primary);
      line-height: 1.6;
    }

    .app-container {
      display: grid;
      grid-template-columns: 280px 1fr;
      max-width: 1400px;
      margin: 0 auto;
      min-height: 100vh;
    }

    /* Sidebar */
    .sidebar {
      position: sticky;
      top: 0;
      height: 100vh;
      overflow-y: auto;
      padding: 24px 0;
      border-right: 1px solid var(--border);
      background: var(--bg-secondary);
    }

    .sidebar-header {
      padding: 0 20px 24px;
      border-bottom: 1px solid var(--border);
      margin-bottom: 24px;
    }

    .sidebar-title {
      font-size: 14px;
      font-weight: 600;
      letter-spacing: 0.5px;
      text-transform: uppercase;
      color: var(--text-tertiary);
    }

    .sidebar-nav {
      list-style: none;
      padding: 0;
      margin: 0;
    }

    .sidebar-nav li {
      margin: 0;
    }

    .nav-link {
      display: block;
      padding: 10px 20px;
      color: var(--text-secondary);
      text-decoration: none;
      font-size: 15px;
      transition: all 0.2s var(--ease);
      border-left: 3px solid transparent;
    }

    .nav-link:hover {
      color: var(--text-primary);
      background: var(--bg-tertiary);
    }

    .nav-link.active {
      color: var(--accent);
      border-left-color: var(--accent);
      background: var(--bg-primary);
    }

    /* Main content */
    .main-content {
      padding: 40px 60px;
      overflow-y: auto;
    }

    .doc-card {
      margin-bottom: 80px;
    }

    .doc-header h1 {
      font-size: 32px;
      font-weight: 700;
      margin: 0 0 12px 0;
      line-height: 1.2;
    }

    .doc-content {
      font-size: 16px;
      color: var(--text-primary);
    }

    .doc-content h2 {
      font-size: 24px;
      font-weight: 600;
      margin: 36px 0 16px 0;
      padding-top: 20px;
      border-top: 1px solid var(--border);
    }

    .doc-content h3 {
      font-size: 18px;
      font-weight: 600;
      margin: 24px 0 12px 0;
    }

    .doc-content p {
      margin: 16px 0;
      color: var(--text-primary);
    }

    .doc-content a {
      color: var(--accent);
      text-decoration: none;
      font-weight: 500;
    }

    .doc-content a:hover {
      color: var(--accent-hover);
    }

    .doc-content code {
      background: var(--bg-secondary);
      padding: 2px 6px;
      border-radius: 4px;
      font-family: 'Menlo', 'Monaco', monospace;
      font-size: 14px;
    }

    .doc-content pre {
      background: var(--bg-secondary);
      padding: 16px;
      border-radius: var(--radius-md);
      overflow-x: auto;
      border: 1px solid var(--border);
    }

    .doc-content pre code {
      background: none;
      padding: 0;
    }

    .doc-content ul, .doc-content ol {
      margin: 16px 0;
      padding-left: 24px;
    }

    .doc-content li {
      margin: 8px 0;
    }

    .doc-content blockquote {
      margin: 16px 0;
      padding: 12px 16px;
      border-left: 3px solid var(--accent);
      background: var(--bg-secondary);
      border-radius: var(--radius-sm);
    }

    .doc-content table {
      border-collapse: collapse;
      width: 100%;
      margin: 16px 0;
    }

    .doc-content th, .doc-content td {
      border: 1px solid var(--border);
      padding: 12px;
      text-align: left;
    }

    .doc-content th {
      background: var(--bg-secondary);
      font-weight: 600;
    }

    /* Search bar (placeholder for future enhancement) */
    .search-box {
      padding: 0 20px 20px;
    }

    .search-input {
      width: 100%;
      padding: 8px 12px;
      border: 1px solid var(--border);
      border-radius: var(--radius-md);
      background: var(--bg-primary);
      color: var(--text-primary);
      font-size: 14px;
    }

    /* Responsive */
    @media (max-width: 768px) {
      .app-container {
        grid-template-columns: 1fr;
      }
      .sidebar {
        position: relative;
        height: auto;
        border-right: none;
        border-bottom: 1px solid var(--border);
      }
      .main-content {
        padding: 24px;
      }
    }

    /* Scrollbar */
    ::-webkit-scrollbar {
      width: 8px;
      height: 8px;
    }
    ::-webkit-scrollbar-track {
      background: transparent;
    }
    ::-webkit-scrollbar-thumb {
      background: var(--text-tertiary);
      border-radius: 4px;
    }
    ::-webkit-scrollbar-thumb:hover {
      background: var(--text-secondary);
    }
  </style>
</head>
<body>
  <div class="app-container">
    <aside class="sidebar">
      <div class="sidebar-header">
        <h2 class="sidebar-title">📚 Manual</h2>
      </div>
      <nav class="sidebar-nav">
        ${navItems}
      </nav>
    </aside>
    <main class="main-content">
      ${docCards}
    </main>
  </div>

  <script>
    // Smooth active link highlighting
    const links = document.querySelectorAll('.nav-link');
    const sections = document.querySelectorAll('.doc-card');

    function updateActiveLink() {
      const current = Array.from(sections).findIndex(section => {
        const rect = section.getBoundingClientRect();
        return rect.top <= 100;
      });

      links.forEach(link => link.classList.remove('active'));
      if (current >= 0 && links[current]) {
        links[current].classList.add('active');
      }
    }

    window.addEventListener('scroll', updateActiveLink);
    updateActiveLink();

    // Keyboard navigation
    document.addEventListener('keydown', e => {
      if (e.key === 'j' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault();
        const current = Array.from(links).findIndex(l => l.classList.contains('active'));
        if (current < links.length - 1) {
          links[current + 1].click();
        }
      }
      if (e.key === 'k' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault();
        const current = Array.from(links).findIndex(l => l.classList.contains('active'));
        if (current > 0) {
          links[current - 1].click();
        }
      }
    });
  </script>
</body>
</html>`;

  return html;
}

function markdownToHtml(md) {
  let html = md;

  // Headings (before other replacements)
  html = html.replace(/^### (.+)$/gm, '<h3>$1</h3>');
  html = html.replace(/^## (.+)$/gm, '<h2>$1</h2>');
  html = html.replace(/^# (.+)$/gm, '<h1>$1</h1>');

  // Code blocks (preserve as-is)
  const codeBlockRegex = /```[\w]*\n([\s\S]*?)```/g;
  const codeBlocks = [];
  html = html.replace(codeBlockRegex, (match, code) => {
    const placeholder = `__CODE_BLOCK_${codeBlocks.length}__`;
    codeBlocks.push(`<pre><code>${esc(code)}</code></pre>`);
    return placeholder;
  });

  // Tables (preserve as-is)
  const tableRegex = /\|[\s\S]*?\|(?:\n\|[-:\s|]+\|)?[\s\S]*?\n(?!\|)/;
  const tables = [];
  html = html.replace(tableRegex, (match) => {
    const placeholder = `__TABLE_${tables.length}__`;
    const rows = match.trim().split('\n');
    const table = '<table>\n' + rows.map((row, idx) => {
      const cells = row.split('|').filter(c => c.trim()).map(c => c.trim());
      if (idx === 1 && cells.every(c => /^[:—-]+$/.test(c))) return ''; // Skip separator
      const tag = idx === 0 ? 'th' : 'td';
      return `<tr>${cells.map(c => `<${tag}>${c}</${tag}>`).join('')}</tr>`;
    }).filter(r => r).join('\n') + '\n</table>';
    tables.push(table);
    return placeholder;
  });

  // Lists
  const listItems = [];
  html = html.replace(/^[\s]*[-*] (.+)$/gm, (match) => {
    listItems.push(match.trim());
    return '__LIST_ITEM__';
  });

  // Wrap consecutive list items in <ul>
  html = html.replace(/(__LIST_ITEM__\n?)+/g, (match) => {
    const items = listItems.splice(0, match.split('__LIST_ITEM__').length - 1);
    return '<ul>\n' + items.map(item => {
      const text = item.replace(/^[-*]\s+/, '');
      return `<li>${text}</li>`;
    }).join('\n') + '\n</ul>';
  });

  // Inline formatting
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
  html = html.replace(/\*(.+?)\*/g, '<em>$1</em>');
  html = html.replace(/`([^`]+)`/g, '<code>$1</code>');

  // Links
  html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');

  // Blockquotes
  html = html.replace(/^> (.+)$/gm, '<blockquote>$1</blockquote>');

  // Paragraphs (double newline indicates new paragraph)
  html = html.split('\n\n').map(para => {
    para = para.trim();
    if (!para || para.startsWith('<')) return para;
    return `<p>${para}</p>`;
  }).join('\n');

  // Restore code blocks and tables
  codeBlocks.forEach((block, idx) => {
    html = html.replace(`__CODE_BLOCK_${idx}__`, block);
  });
  tables.forEach((table, idx) => {
    html = html.replace(`__TABLE_${idx}__`, table);
  });

  return html;
}

function main() {
  const { docs, missing } = loadDocs();
  const html = buildHTML(docs);

  fs.writeFileSync(OUT, html, 'utf8');

  const pages = Math.ceil(html.length / 30000);
  console.log(`✓ Generated manual.html (v2.1.4, ${pages} pages, ${(html.length / 1024 / 1024).toFixed(1)} MB)`);
}

main();
