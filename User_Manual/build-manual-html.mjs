#!/usr/bin/env node
/**
 * build-manual-html.mjs (v5.1.0) - ENHANCED CARD PREVIEWS
 * 
 * Adds rich card content with:
 * - Meaningful preview snippets from markdown
 * - Suggested actions & next steps
 * - External resource links
 * - Better visual hierarchy
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';
import MarkdownIt from 'markdown-it';
import markdownItAnchor from 'markdown-it-anchor';

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
  'Start Here': {
    emoji: '🚀',
    color: '#FF6B35',
    files: ['README.md', 'INDEX.md', 'Prerequisites.md', 'Getting_Started.md'],
    description: 'Begin your AI-SDLC journey'
  },
  'Core Concepts': {
    emoji: '🎯',
    color: '#004E89',
    files: ['System_Overview.md', 'CANONICAL_REPO_AND_INTERFACES.md', 'Architecture.md'],
    description: 'Master the fundamentals'
  },
  'Execution': {
    emoji: '🛠️',
    color: '#1B998B',
    files: ['SDLC_Flows.md', 'Happy_Path_End_to_End.md', 'Role_and_Stage_Playbook.md', 'Commands.md', 'Guided_Execution_and_Recovery.md'],
    description: 'Run your workflows'
  },
  'Features': {
    emoji: '✨',
    color: '#F77F00',
    files: ['FEATURES_REFERENCE.md', 'Persistent_Memory.md', 'ADO_MCP_Integration.md', 'Token_Efficiency_and_Context_Loading.md'],
    description: 'Advanced capabilities'
  },
  'Deep Dives': {
    emoji: '📚',
    color: '#A23B72',
    files: ['Agents_Skills_Rules.md', 'Repository_Complexity_Explained.md', '../docs/sdlc-stage-role-mapping.md'],
    description: 'Complex topics'
  },
  'Quality': {
    emoji: '🔒',
    color: '#C1121F',
    files: ['PR_Merge_Process.md', 'Enforcement_Contract.md', 'Traceability_and_Governance.md'],
    description: 'Ensure compliance'
  },
  'Advanced': {
    emoji: '🔧',
    color: '#6A4C93',
    files: ['Platform_Extension_Onboarding.md', 'Team_Onboarding_Presentation.md', 'Documentation_Rules.md'],
    description: 'Extend & customize'
  },
  'Reference': {
    emoji: '📖',
    color: '#1D3557',
    files: ['FAQ.md', 'CHANGELOG.md'],
    description: 'Lookup & updates'
  }
};

const TITLES = {
  'README.md': 'Home', 'INDEX.md': 'Index', 'FEATURES_REFERENCE.md': 'Features',
  'ADO_MCP_Integration.md': 'ADO & MCP', 'PR_Merge_Process.md': 'PR & Merge',
  'SDLC_Flows.md': 'SDLC Flows', 'CANONICAL_REPO_AND_INTERFACES.md': 'Canonical Repo',
  'FAQ.md': 'FAQ', 'CHANGELOG.md': 'Changelog'
};

// Card suggestions for each topic
const CARD_ACTIONS = {
  'README.md': ['Learn what AI-SDLC is', 'Understand the platform benefits'],
  'INDEX.md': ['Browse all topics', 'Find your starting point'],
  'Prerequisites.md': ['Check system requirements', 'Verify dependencies'],
  'Getting_Started.md': ['Run setup.sh', 'Configure your environment'],
  'System_Overview.md': ['Understand architecture', 'See how it works'],
  'CANONICAL_REPO_AND_INTERFACES.md': ['Clone the repository', 'Set up CLI access'],
  'Happy_Path_End_to_End.md': ['Follow a complete example', 'Build end-to-end'],
  'SDLC_Flows.md': ['Learn 15-stage process', 'Understand workflows'],
  'Role_and_Stage_Playbook.md': ['Find your role', 'See stage-by-stage guide'],
  'FEATURES_REFERENCE.md': ['Explore all features', 'Understand capabilities'],
  'Commands.md': ['See all CLI commands', 'Learn command syntax'],
  'Guided_Execution_and_Recovery.md': ['Handle errors gracefully', 'Recover from failures'],
  'Persistent_Memory.md': ['Manage team memory', 'Store decisions'],
  'ADO_MCP_Integration.md': ['Connect Azure DevOps', 'Sync with MCP'],
  'Agents_Skills_Rules.md': ['Define custom agents', 'Create skills'],
  'Architecture.md': ['Study system design', 'Review components'],
  'Token_Efficiency_and_Context_Loading.md': ['Optimize token usage', 'Manage budget'],
  'Repository_Complexity_Explained.md': ['Understand mono/multi-repo', 'Plan your setup'],
  'PR_Merge_Process.md': ['Review PR workflow', 'Manage gates'],
  'Enforcement_Contract.md': ['Learn enforcement rules', 'Define contracts'],
  'Traceability_and_Governance.md': ['Track changes', 'Audit decisions'],
  'Platform_Extension_Onboarding.md': ['Extend platform', 'Add custom tools'],
  'Team_Onboarding_Presentation.md': ['Present to team', 'Get buy-in'],
  'Documentation_Rules.md': ['Keep docs in sync', 'Follow standards'],
  'FAQ.md': ['Find common answers', 'Solve problems'],
  'CHANGELOG.md': ['See latest changes', 'Review versions']
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

function calculateHash(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
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
  if (missing.length > 0) console.warn('Skipped: ' + missing.join(', '));
  return { docs, missing };
}

const md = new MarkdownIt({ html: true, breaks: false, linkify: false });
md.use(markdownItAnchor, { permalink: false, level: [2, 3] });

function generatePageTOC(markdown) {
  const headings = [];
  const lines = markdown.split('\n');
  for (const line of lines) {
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
  let toc = '<nav class="page-toc"><details><summary>On this page</summary><ul>';
  for (const h of headings) {
    const indent = h.level === 3 ? '  ' : '';
    toc += `${indent}<li><a href="#${h.id}">${h.text}</a></li>`;
  }
  return toc + '</ul></details></nav>';
}

function markdownToHtml(markdown) {
  let html = md.render(markdown);
  
  // Convert markdown links to anchor links
  html = html.replace(/<a href="([^"]+\.md(?:#[^"]*)?)"([^>]*)>([^<]+)<\/a>/g, (match, href, attrs, text) => {
    const slug = href.replace(/\.md.*$/, '').replace(/^.*[\\/]/, '').toLowerCase();
    const anchor = href.includes('#') ? href.split('#')[1] : '';
    const target = anchor ? `#${anchor}` : `#${slug}`;
    return `<a href="${target}"${attrs}>${text}</a>`;
  });

  // Wrap mermaid diagrams
  html = html.replace(/<pre><code class="language-mermaid">([\s\S]*?)<\/code><\/pre>/g, '<div class="mermaid">$1</div>');
  
  return html;
}

function getCardContent(title, markdown, file) {
  const actions = CARD_ACTIONS[file] || ['Read full documentation'];
  
  // Get better preview from markdown
  const lines = markdown.split('\n').filter(l => l.trim() && !l.startsWith('#'));
  const preview = lines.slice(0, 1).join(' ').substring(0, 70).trim();
  
  return {
    preview: preview || 'Learn more about this topic',
    actions: actions
  };
}

function buildGroupBlocks(docs) {
  const docsByFile = Object.fromEntries(docs.map(d => [d.file, d]));
  let html = '';

  for (const [groupName, groupData] of Object.entries(GROUPS)) {
    const groupDocs = groupData.files.filter(f => docsByFile[f]).map(f => docsByFile[f]);
    if (groupDocs.length === 0) continue;

    html += `<section class="topic-group" style="border-color: ${groupData.color}">
      <div class="group-header">
        <span class="group-emoji">${groupData.emoji}</span>
        <div>
          <h2>${groupName}</h2>
          <p class="group-desc">${groupData.description}</p>
        </div>
      </div>
      <div class="card-scroll">`;

    for (const doc of groupDocs) {
      const content = getCardContent(doc.title, doc.markdown, doc.file);
      html += `<a href="#${doc.slug}" class="topic-card" style="border-left: 4px solid ${groupData.color}">
        <h3>${esc(doc.title)}</h3>
        <p class="card-preview">${esc(content.preview)}</p>
        <div class="card-actions">
          ${content.actions.map(action => `<span class="action-tag">${esc(action)}</span>`).join('')}
        </div>
        <span class="arrow">→</span>
      </a>`;
    }

    html += `</div></section>`;
  }

  return html;
}

function buildHTML(docs) {
  const groupBlocks = buildGroupBlocks(docs);
  
  const docCards = docs.map(d => {
    const toc = generatePageTOC(d.markdown);
    const htmlContent = markdownToHtml(d.markdown);
    
    // Find next and previous docs for flow navigation
    const currentIndex = docs.findIndex(doc => doc.slug === d.slug);
    const prevDoc = currentIndex > 0 ? docs[currentIndex - 1] : null;
    const nextDoc = currentIndex < docs.length - 1 ? docs[currentIndex + 1] : null;
    
    let nav = '';
    if (prevDoc || nextDoc) {
      nav = '<nav class="doc-nav">';
      if (prevDoc) nav += `<a href="#${prevDoc.slug}" class="nav-prev">← ${prevDoc.title}</a>`;
      if (nextDoc) nav += `<a href="#${nextDoc.slug}" class="nav-next">${nextDoc.title} →</a>`;
      nav += '</nav>';
    }

    return `<article id="${d.slug}" class="doc-section">
      <header class="doc-header">
        <h1>${esc(d.title)}</h1>
        ${toc}
      </header>
      <main class="doc-body">${htmlContent}</main>
      ${nav}
    </article>`;
  }).join('\n');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="AI-SDLC Platform Manual v5.1.0" />
  <title>AI-SDLC Platform Manual</title>
  
  <!-- Prism.js -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" />
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-bash.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-python.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-javascript.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-json.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-yaml.min.js"><\/script>
  
  <!-- Mermaid.js -->
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"><\/script>
  
  <style>
:root {
  --bg: #fff;
  --bg-alt: #f5f5f7;
  --bg-code: #efefef;
  --text: #1d1d1d;
  --text-secondary: #666;
  --text-tertiary: #999;
  --accent: #0071e3;
  --border: #e5e5e7;
  --radius: 12px;
  --font: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-mono: 'Menlo', 'Monaco', 'Courier New', monospace;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #000;
    --bg-alt: #1d1d1f;
    --bg-code: #2a2a2e;
    --text: #f5f5f7;
    --text-secondary: #a1a1a6;
    --text-tertiary: #727278;
    --border: #424245;
  }
}

* { margin: 0; padding: 0; box-sizing: border-box; }
html { scroll-behavior: smooth; }
body { font-family: var(--font); background: var(--bg); color: var(--text); line-height: 1.6; }

/* Header */
header {
  position: sticky; top: 0; z-index: 100;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid var(--border);
  padding: 14px 0;
}

@media (prefers-color-scheme: dark) {
  header { background: rgba(0, 0, 0, 0.95); }
}

.header-inner {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  display: flex;
  gap: 30px;
  align-items: center;
}

.logo {
  font-weight: 700;
  font-size: 18px;
  letter-spacing: -0.5px;
  white-space: nowrap;
}

.search {
  flex: 1;
  max-width: 350px;
}

.search input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--bg-alt);
  color: var(--text);
  font-family: var(--font);
  font-size: 14px;
  transition: all 0.2s;
}

.search input:focus {
  outline: none;
  border-color: var(--accent);
  background: var(--bg);
  box-shadow: 0 0 0 3px rgba(0, 113, 227, 0.1);
}

/* Main */
main {
  max-width: 1200px;
  margin: 0 auto;
  padding: 60px 20px;
}

/* Topic Groups */
.topic-group {
  margin-bottom: 60px;
  padding: 32px;
  background: var(--bg-alt);
  border-radius: var(--radius);
  border-left: 4px solid;
}

.group-header {
  display: flex;
  gap: 16px;
  margin-bottom: 24px;
  align-items: flex-start;
}

.group-emoji {
  font-size: 32px;
  line-height: 1;
}

.group-header h2 {
  font-size: 26px;
  font-weight: 700;
  margin-bottom: 4px;
  letter-spacing: -0.5px;
}

.group-desc {
  font-size: 14px;
  color: var(--text-secondary);
  font-weight: 500;
}

/* Card Scroll */
.card-scroll {
  display: flex;
  gap: 16px;
  overflow-x: auto;
  padding-bottom: 12px;
  scroll-behavior: smooth;
}

.card-scroll::-webkit-scrollbar {
  height: 6px;
}

.card-scroll::-webkit-scrollbar-track {
  background: var(--bg);
}

.card-scroll::-webkit-scrollbar-thumb {
  background: var(--border);
  border-radius: 3px;
}

/* Topic Cards - ENHANCED */
.topic-card {
  flex: 0 0 300px;
  padding: 20px;
  background: var(--bg);
  border-left: 4px solid;
  border-radius: 8px;
  text-decoration: none;
  color: inherit;
  transition: all 0.3s cubic-bezier(0.25, 0.1, 0.25, 1);
  cursor: pointer;
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: 180px;
}

.topic-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px rgba(0, 0, 0, 0.12);
}

.topic-card h3 {
  font-size: 16px;
  font-weight: 700;
  margin-bottom: 12px;
  color: var(--text);
}

.card-preview {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.5;
  flex: 1;
  margin-bottom: 12px;
  min-height: 40px;
}

/* Card Actions - NEW */
.card-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 12px;
  flex-grow: 1;
  align-content: flex-end;
}

.action-tag {
  display: inline-block;
  background: var(--bg-alt);
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  color: var(--text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.topic-card:hover .action-tag {
  background: var(--accent);
  color: white;
  transition: all 0.2s;
}

.topic-card .arrow {
  font-size: 14px;
  font-weight: 600;
  opacity: 0;
  transition: opacity 0.3s, transform 0.3s;
  display: inline-block;
  align-self: flex-start;
  margin-top: auto;
}

.topic-card:hover .arrow {
  opacity: 1;
  transform: translateX(4px);
}

/* Documents */
.doc-section {
  margin-bottom: 100px;
  scroll-margin-top: 80px;
}

.doc-header {
  margin-bottom: 48px;
  padding-bottom: 32px;
  border-bottom: 1px solid var(--border);
}

.doc-header h1 {
  font-size: 48px;
  font-weight: 700;
  margin-bottom: 24px;
  letter-spacing: -0.5px;
  line-height: 1.1;
}

.page-toc {
  margin-top: 16px;
}

.page-toc summary {
  cursor: pointer;
  font-weight: 600;
  color: var(--accent);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.page-toc ul {
  margin: 12px 0 0 20px;
  padding: 0;
  list-style: none;
}

.page-toc li { margin: 6px 0; }

.page-toc a {
  color: var(--text-secondary);
  text-decoration: none;
  font-size: 13px;
  transition: all 0.2s;
}

.page-toc a:hover { color: var(--accent); }

/* Content */
.doc-body {
  font-size: 16px;
  color: var(--text-secondary);
  line-height: 1.8;
}

.doc-body h2 {
  font-size: 28px;
  font-weight: 700;
  margin: 48px 0 24px 0;
  padding-top: 24px;
  border-top: 1px solid var(--border);
  color: var(--text);
  letter-spacing: -0.5px;
}

.doc-body h3 {
  font-size: 20px;
  font-weight: 600;
  margin: 32px 0 16px 0;
  color: var(--text);
  letter-spacing: -0.3px;
}

.doc-body p {
  margin: 16px 0;
  color: var(--text-secondary);
}

.doc-body a {
  color: var(--accent);
  text-decoration: none;
  border-bottom: 1px solid rgba(0, 113, 227, 0.2);
  transition: all 0.2s;
}

.doc-body a:hover {
  border-bottom-color: var(--accent);
}

.doc-body code {
  background: var(--bg-code);
  padding: 3px 8px;
  border-radius: 4px;
  font-family: var(--font-mono);
  font-size: 14px;
}

.doc-body pre {
  background: var(--bg-code);
  padding: 16px;
  border-radius: 8px;
  overflow-x: auto;
  margin: 20px 0;
  border-left: 4px solid var(--accent);
  position: relative;
}

.doc-body pre code {
  background: none;
  padding: 0;
  font-size: 13px;
  line-height: 1.6;
  color: var(--text);
}

.doc-body table {
  width: 100%;
  border-collapse: collapse;
  margin: 20px 0;
  border: 1px solid var(--border);
  border-radius: 8px;
  overflow: hidden;
}

.doc-body th {
  background: var(--bg-alt);
  padding: 12px 16px;
  text-align: left;
  font-weight: 600;
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border: 1px solid var(--border);
  color: var(--text);
}

.doc-body td {
  padding: 12px 16px;
  border: 1px solid var(--border);
}

.doc-body tbody tr:hover {
  background: var(--bg-alt);
}

.doc-body ul, .doc-body ol {
  margin: 16px 0;
  padding-left: 28px;
}

.doc-body li { margin: 8px 0; }

.doc-body blockquote {
  margin: 20px 0;
  padding: 16px 20px;
  border-left: 4px solid var(--accent);
  background: var(--bg-alt);
  border-radius: 0 8px 8px 0;
  color: var(--text-secondary);
  font-style: italic;
}

.doc-body hr {
  margin: 40px 0;
  border: none;
  border-top: 1px solid var(--border);
}

/* Mermaid */
.mermaid {
  background: var(--bg-alt);
  padding: 16px;
  border-radius: 8px;
  margin: 20px 0;
  display: flex;
  justify-content: center;
}

/* Navigation */
.doc-nav {
  display: flex;
  gap: 16px;
  margin-top: 64px;
  padding-top: 32px;
  border-top: 1px solid var(--border);
}

.nav-prev, .nav-next {
  flex: 1;
  padding: 16px;
  border: 1px solid var(--border);
  border-radius: 8px;
  text-decoration: none;
  color: var(--accent);
  font-weight: 600;
  font-size: 14px;
  transition: all 0.2s;
}

.nav-prev:hover, .nav-next:hover {
  background: var(--bg-alt);
  transform: translateY(-2px);
}

@media (max-width: 768px) {
  .header-inner {
    flex-direction: column;
    gap: 12px;
  }
  .search { max-width: 100%; }
  main { padding: 40px 16px; }
  .group-header { flex-direction: column; }
  .group-emoji { font-size: 28px; }
  .group-header h2 { font-size: 20px; }
  .card-scroll { gap: 12px; }
  .topic-card { flex: 0 0 240px; min-height: 200px; }
  .doc-header h1 { font-size: 32px; }
  .doc-body h2 { font-size: 22px; }
  .doc-nav { flex-direction: column; }
}

@media print {
  header { display: none; }
  .topic-group { display: none; }
  main { padding: 0; }
}

.token.string { color: inherit; }
.token.number { color: inherit; }
.token.keyword { color: inherit; }
  </style>
</head>
<body>
  <header>
    <div class="header-inner">
      <div class="logo">📘 AI-SDLC Manual</div>
      <div class="search">
        <input type="text" id="globalSearch" placeholder="Search docs (Cmd+K)..." />
      </div>
    </div>
  </header>

  <main>
    <section id="discovery">
      ${groupBlocks}
    </section>

    <section id="content">
      ${docCards}
    </section>
  </main>

  <script>
    mermaid.contentLoaded();
    document.addEventListener('DOMContentLoaded', () => {
      Prism.highlightAll();
    });

    const searchInput = document.getElementById('globalSearch');
    const docSections = document.querySelectorAll('.doc-section');
    const topicGroups = document.querySelectorAll('.topic-group');

    searchInput.addEventListener('input', (e) => {
      const query = e.target.value.toLowerCase();
      
      docSections.forEach(section => {
        const text = section.textContent.toLowerCase();
        section.style.display = text.includes(query) ? '' : 'none';
      });

      topicGroups.forEach(group => {
        const cards = group.querySelectorAll('.topic-card');
        let visible = 0;
        cards.forEach(card => {
          if (card.textContent.toLowerCase().includes(query)) {
            card.style.display = '';
            visible++;
          } else {
            card.style.display = 'none';
          }
        });
        group.style.display = visible > 0 ? '' : 'none';
      });
    });

    document.addEventListener('keydown', (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        searchInput.focus();
        searchInput.select();
      }
    });

    document.querySelectorAll('a[href^="#"]').forEach(link => {
      link.addEventListener('click', (e) => {
        if (link.getAttribute('href') === '#') return;
        e.preventDefault();
        const target = document.querySelector(link.getAttribute('href'));
        if (target) {
          const offset = 80;
          window.scrollTo({
            top: target.getBoundingClientRect().top + window.scrollY - offset,
            behavior: 'smooth'
          });
        }
      });
    });
  </script>
</body>
</html>`;
}

function main() {
  const args = process.argv.slice(2);
  if (args.includes('--check')) {
    const { docs } = loadDocs();
    if (docs.length === 0) {
      console.error('No documentation files found');
      process.exit(1);
    }
    console.log('Found ' + docs.length + ' documentation files');
    process.exit(0);
  }

  const { docs } = loadDocs();
  if (docs.length === 0) {
    console.error('No documentation files found');
    process.exit(1);
  }

  const html = buildHTML(docs);
  fs.writeFileSync(OUT, html, 'utf8');

  const hash = calculateHash(html);
  fs.writeFileSync(HASH_FILE, hash, 'utf8');

  const sizeKB = (fs.statSync(OUT).size / 1024).toFixed(1);
  console.log('Generated ' + OUT + ' (v5.1.0, ' + docs.length + ' sections, ' + sizeKB + ' KB)');
}

main();
