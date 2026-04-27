#!/usr/bin/env node
/**
 * build-manual-html.mjs (v7.5.0) - ADD GO TO TOP BUTTON
 *
 * Changes:
 * - Add floating "Go to TOP" button
 * - Shows when scrolled down 300px
 * - Click to smooth scroll to top
 * - Stylish with neon accent
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
    color: '#00d9ff',
    files: ['README.md', 'INDEX.md', 'Prerequisites.md', 'Getting_Started.md'],
    description: 'Begin your AI-SDLC journey'
  },
  'Core Concepts': {
    emoji: '🎯',
    color: '#ff00ff',
    files: ['System_Overview.md', 'CANONICAL_REPO_AND_INTERFACES.md', 'Architecture.md'],
    description: 'Master the fundamentals'
  },
  'Execution': {
    emoji: '🛠️',
    color: '#00d9ff',
    files: ['SDLC_Flows.md', 'Happy_Path_End_to_End.md', 'Role_and_Stage_Playbook.md', 'Commands.md', 'Guided_Execution_and_Recovery.md'],
    description: 'Run your workflows'
  },
  'Features': {
    emoji: '✨',
    color: '#ff00ff',
    files: ['FEATURES_REFERENCE.md', 'Persistent_Memory.md', 'ADO_MCP_Integration.md', 'Token_Efficiency_and_Context_Loading.md'],
    description: 'Advanced capabilities'
  },
  'Deep Dives': {
    emoji: '📚',
    color: '#00d9ff',
    files: ['Agents_Skills_Rules.md', 'Repository_Complexity_Explained.md', '../docs/sdlc-stage-role-mapping.md'],
    description: 'Complex topics'
  },
  'Quality': {
    emoji: '🔒',
    color: '#ff00ff',
    files: ['PR_Merge_Process.md', 'Enforcement_Contract.md', 'Traceability_and_Governance.md'],
    description: 'Ensure compliance'
  },
  'Advanced': {
    emoji: '🔧',
    color: '#00d9ff',
    files: ['Platform_Extension_Onboarding.md', 'Team_Onboarding_Presentation.md', 'Documentation_Rules.md'],
    description: 'Extend & customize'
  },
  'Reference': {
    emoji: '📖',
    color: '#ff00ff',
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
  if (missing.length > 0) {
    console.log(`⚠️  Missing ${missing.length} files`);
  }
  return docs;
}

function markdownToHtml(markdown) {
  const md = new MarkdownIt({
    html: false,
    linkify: true,
    typographer: true,
    highlight: function(str, lang) {
      if (lang) {
        return `<pre class="language-${lang}"><code class="language-${lang}">${esc(str)}</code></pre>`;
      }
      return `<pre><code>${esc(str)}</code></pre>`;
    }
  });

  md.use(markdownItAnchor, {
    slugify: s => s.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]/g, '')
  });

  let html = md.render(markdown);
  html = html.replace(/<pre><code class="language-mermaid">([\s\S]*?)<\/code><\/pre>/g,
    '<div class="mermaid">$1</div>');

  return html;
}

function getCardContent(title, markdown, file) {
  const actions = CARD_ACTIONS[file] || ['Read full documentation'];
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

    html += `<section class="topic-group" style="--group-color: ${groupData.color}">
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
      html += `<a href="#${doc.slug}" class="topic-card" style="--card-accent: ${groupData.color}" data-title="${esc(doc.title)}" data-keywords="${esc(content.preview)}">
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

function buildSearchIndex(docs) {
  const index = docs.map(d => ({
    slug: d.slug,
    title: d.title,
    content: d.markdown.replace(/#/g, '').substring(0, 500)
  }));

  return JSON.stringify(index);
}

function buildHTML(docs) {
  const groupBlocks = buildGroupBlocks(docs);
  const searchIndex = buildSearchIndex(docs);

  const docCards = docs.map(d => {
    const htmlContent = markdownToHtml(d.markdown);

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
  <meta name="description" content="AI-SDLC Platform Manual v7.5.0" />
  <title>AI-SDLC Platform Manual</title>

  <!-- Prism.js -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" />
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-bash.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-shell-session.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-python.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-javascript.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-json.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-yaml.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-markdown.min.js"><\/script>

  <!-- Mermaid.js -->
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"><\/script>
  <script>mermaid.initialize({ startOnLoad: true, theme: 'dark' });<\/script>

  <style>
:root {
  --bg: #0a0a0f;
  --bg-alt: #14141b;
  --bg-card: #1a1a24;
  --bg-code: #0f0f13;
  --text: #e5e5ff;
  --text-secondary: #a0a0c0;
  --text-tertiary: #6b6b8e;
  --accent-cyan: #00d9ff;
  --accent-magenta: #ff00ff;
  --accent-purple: #8b5cf6;
  --border: #2a2a3e;
  --border-subtle: #1f1f2e;
  --radius: 12px;
  --radius-sm: 8px;
  --font: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', sans-serif;
  --font-serif: 'Georgia', 'Garamond', serif;
  --font-mono: 'Menlo', 'Monaco', 'Courier New', monospace;
  --shadow-sm: 0 2px 8px rgba(0, 217, 255, 0.05);
  --shadow-md: 0 8px 24px rgba(255, 0, 255, 0.08);
  --shadow-lg: 0 20px 40px rgba(0, 0, 0, 0.4);
  --transition: all 0.3s cubic-bezier(0.25, 0.1, 0.25, 1);
  --header-height: 56px;
}

* { margin: 0; padding: 0; box-sizing: border-box; }
html { scroll-behavior: smooth; }
body {
  font-family: var(--font);
  background: linear-gradient(135deg, var(--bg) 0%, #0f0f18 100%);
  color: var(--text);
  line-height: 1.6;
}

/* Header */
header {
  position: sticky; top: 0; z-index: 100;
  background: rgba(10, 10, 15, 0.92);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid var(--border);
  padding: 12px 0;
  height: var(--header-height);
  box-shadow: var(--shadow-sm);
}

.header-inner {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 24px;
  display: flex;
  gap: 24px;
  align-items: center;
  justify-content: space-between;
  height: 100%;
}

.logo {
  font-weight: 800;
  font-size: 16px;
  letter-spacing: -0.8px;
  background: linear-gradient(90deg, var(--accent-cyan), var(--accent-magenta));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  white-space: nowrap;
  flex-shrink: 0;
}

.search {
  flex: 1;
  max-width: 400px;
  position: relative;
}

.search input {
  width: 100%;
  padding: 8px 14px;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--bg-card);
  color: var(--text);
  font-family: var(--font);
  font-size: 13px;
  transition: var(--transition);
  height: 40px;
}

.search input:focus {
  outline: none;
  border-color: var(--accent-cyan);
  box-shadow: 0 0 0 2px rgba(0, 217, 255, 0.15);
}

.search-results {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-top: none;
  border-radius: 0 0 6px 6px;
  max-height: 400px;
  overflow-y: auto;
  display: none;
  z-index: 1000;
  box-shadow: var(--shadow-lg);
  margin-top: 4px;
}

.search-results.active { display: block; }

.search-result-item {
  padding: 12px 14px;
  border-bottom: 1px solid var(--border-subtle);
  cursor: pointer;
  transition: var(--transition);
  text-decoration: none;
  color: inherit;
  display: block;
}

.search-result-item:last-child { border-bottom: none; }
.search-result-item:hover { background: var(--bg-alt); }

.search-result-title {
  font-weight: 700;
  font-size: 13px;
  color: var(--accent-cyan);
  margin-bottom: 4px;
}

.search-result-snippet {
  font-size: 11px;
  color: var(--text-tertiary);
  line-height: 1.3;
}

/* Go to Top Button */
#go-to-top {
  position: fixed;
  bottom: 32px;
  right: 32px;
  width: 48px;
  height: 48px;
  background: linear-gradient(135deg, var(--accent-cyan), var(--accent-magenta));
  border: none;
  border-radius: 50%;
  cursor: pointer;
  display: none;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  z-index: 99;
  box-shadow: var(--shadow-lg);
  transition: var(--transition);
  opacity: 0;
}

#go-to-top.visible {
  display: flex;
  opacity: 1;
}

#go-to-top:hover {
  transform: translateY(-4px);
  box-shadow: 0 0 30px rgba(0, 217, 255, 0.4);
}

@media (max-width: 768px) {
  #go-to-top {
    bottom: 20px;
    right: 20px;
    width: 44px;
    height: 44px;
    font-size: 18px;
  }
}

/* Main */
main {
  max-width: 1400px;
  margin: 0 auto;
  padding: 32px 24px;
}

/* Topic Groups */
.topic-group {
  margin-bottom: 40px;
  padding: 28px;
  background: rgba(26, 26, 36, 0.5);
  border: 1px solid var(--border);
  border-left: 3px solid var(--group-color);
  border-radius: var(--radius);
  backdrop-filter: blur(10px);
  transition: var(--transition);
  overflow: visible;
}

.topic-group:hover {
  background: rgba(26, 26, 36, 0.8);
  border-color: var(--group-color);
}

.group-header {
  display: flex;
  gap: 16px;
  margin-bottom: 20px;
  align-items: flex-start;
}

.group-emoji { font-size: 28px; line-height: 1; }

.group-header h2 {
  font-size: 22px;
  font-weight: 700;
  margin-bottom: 2px;
  letter-spacing: -0.5px;
  color: var(--text);
}

.group-desc {
  font-size: 12px;
  color: var(--text-secondary);
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

/* Card Scroll */
.card-scroll {
  display: flex;
  gap: 14px;
  overflow-x: auto;
  overflow-y: visible;
  padding-bottom: 8px;
  scroll-behavior: smooth;
  -webkit-overflow-scrolling: touch;
  padding-right: 4px;
}

.card-scroll::-webkit-scrollbar { height: 4px; }
.card-scroll::-webkit-scrollbar-track { background: transparent; }
.card-scroll::-webkit-scrollbar-thumb {
  background: var(--text-tertiary);
  border-radius: 2px;
}

.card-scroll::-webkit-scrollbar-thumb:hover {
  background: var(--text-secondary);
}

/* Topic Cards */
.topic-card {
  flex: 0 0 280px;
  padding: 18px;
  background: var(--bg-card);
  border-left: 3px solid var(--card-accent);
  border-radius: var(--radius-sm);
  text-decoration: none;
  color: inherit;
  transition: box-shadow 0.3s, border-color 0.3s, background 0.3s;
  cursor: pointer;
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: 160px;
  border: 1px solid var(--border-subtle);
}

.topic-card::before {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  width: 0;
  height: 0;
  background: radial-gradient(circle, rgba(0,217,255,0.15) 0%, transparent 70%);
  border-radius: 50%;
  transform: translate(-50%, -50%);
  transition: width 0.3s, height 0.3s;
  pointer-events: none;
}

.topic-card:hover::before {
  width: 300px;
  height: 300px;
}

.topic-card:hover {
  box-shadow: 0 0 20px rgba(0, 217, 255, 0.2);
  border-color: var(--card-accent);
  background: rgba(26, 26, 36, 0.9);
}

.topic-card h3 {
  font-size: 15px;
  font-weight: 700;
  margin-bottom: 8px;
  color: var(--text);
  letter-spacing: -0.3px;
  position: relative;
  z-index: 1;
}

.card-preview {
  font-size: 12px;
  color: var(--text-secondary);
  line-height: 1.4;
  flex: 1;
  margin-bottom: 10px;
  position: relative;
  z-index: 1;
}

.card-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
  flex-grow: 1;
  align-content: flex-end;
  position: relative;
  z-index: 1;
}

.action-tag {
  display: inline-block;
  background: rgba(0, 217, 255, 0.1);
  padding: 4px 10px;
  border-radius: 3px;
  font-size: 10px;
  font-weight: 600;
  color: var(--accent-cyan);
  transition: var(--transition);
  letter-spacing: 0.3px;
  border: 1px solid rgba(0, 217, 255, 0.2);
  white-space: nowrap;
  flex-shrink: 0;
}

.topic-card:hover .action-tag {
  background: var(--accent-cyan);
  color: var(--bg);
  border-color: var(--accent-cyan);
}

.arrow {
  opacity: 0;
  transition: opacity 0.3s;
  font-weight: 700;
  color: var(--accent-cyan);
  position: absolute;
  right: 16px;
  top: 50%;
  transform: translateY(-50%);
  z-index: 1;
  flex-shrink: 0;
}

.topic-card:hover .arrow {
  opacity: 1;
}

/* Document Sections */
.doc-section {
  max-width: 900px;
  margin: 0 auto;
  padding: 56px 0 40px;
  scroll-margin-top: calc(var(--header-height) + 20px);
}

.doc-header {
  margin-bottom: 24px;
  padding-bottom: 0;
  border-bottom: none;
}

.doc-header h1 {
  font-size: 40px;
  font-weight: 800;
  margin-bottom: 16px;
  letter-spacing: -1px;
  line-height: 1.2;
  background: linear-gradient(90deg, var(--text), var(--text-secondary));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

/* Body Content */
.doc-body {
  font-size: 15px;
  line-height: 1.8;
  color: var(--text);
}

.doc-body h2 {
  font-size: 26px;
  font-weight: 700;
  margin: 36px 0 16px;
  letter-spacing: -0.5px;
  color: var(--text);
  scroll-margin-top: calc(var(--header-height) + 16px);
}

.doc-body h3 {
  font-size: 20px;
  font-weight: 700;
  margin: 28px 0 12px;
  letter-spacing: -0.3px;
  scroll-margin-top: calc(var(--header-height) + 16px);
}

.doc-body p {
  margin-bottom: 16px;
  color: var(--text-secondary);
}

.doc-body ul, .doc-body ol {
  margin: 16px 0 16px 24px;
}

.doc-body li {
  margin-bottom: 8px;
  color: var(--text-secondary);
}

/* Code */
.doc-body code {
  background: var(--bg-card);
  padding: 2px 6px;
  border-radius: 3px;
  font-family: var(--font-mono);
  font-size: 13px;
  color: var(--accent-cyan);
}

.doc-body pre {
  background: var(--bg-code);
  padding: 14px;
  border-radius: var(--radius-sm);
  overflow-x: auto;
  overflow-y: hidden;
  margin: 20px 0;
  border: 1px solid var(--border);
  box-shadow: var(--shadow-sm);
  transition: var(--transition);
}

.doc-body pre:hover {
  border-color: var(--accent-cyan);
  box-shadow: 0 0 15px rgba(0, 217, 255, 0.1);
}

.doc-body pre code {
  background: none;
  padding: 0;
  color: inherit;
  font-family: var(--font-mono);
  font-size: 13px;
}

/* Prism.js Theme */
code[class*="language-"],
pre[class*="language-"] {
  font-family: var(--font-mono);
  font-size: 13px;
  line-height: 1.5;
}

pre[class*="language-"] {
  background: var(--bg-code) !important;
  border: 1px solid var(--border) !important;
}

/* Tables */
table {
  width: 100%;
  border-collapse: collapse;
  margin: 20px 0;
  font-size: 13px;
}

table th, table td {
  padding: 10px;
  text-align: left;
  border-bottom: 1px solid var(--border-subtle);
}

table th {
  background: var(--bg-card);
  font-weight: 700;
  color: var(--accent-cyan);
}

table tr:hover {
  background: rgba(0, 217, 255, 0.05);
}

/* Blockquotes */
blockquote {
  border-left: 3px solid var(--accent-magenta);
  padding-left: 16px;
  margin: 20px 0;
  color: var(--text-secondary);
  font-style: italic;
}

/* Links */
a {
  color: var(--accent-cyan);
  text-decoration: none;
  transition: var(--transition);
}

a:hover {
  color: var(--accent-magenta);
}

/* Navigation */
.doc-nav {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  margin-top: 48px;
  padding-top: 16px;
  border-top: 1px solid var(--border);
}

.nav-prev, .nav-next {
  padding: 10px 14px;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  font-size: 13px;
  font-weight: 700;
  transition: var(--transition);
}

.nav-prev:hover {
  background: var(--accent-cyan);
  color: var(--bg);
  border-color: var(--accent-cyan);
}

.nav-next:hover {
  background: var(--accent-magenta);
  color: var(--bg);
  border-color: var(--accent-magenta);
}

/* Mermaid */
.mermaid {
  display: flex;
  justify-content: center;
  margin: 20px 0;
  filter: drop-shadow(0 0 15px rgba(0, 217, 255, 0.1));
}

/* Responsive */
@media (max-width: 768px) {
  main { padding: 24px 16px; }
  .header-inner { flex-direction: column; gap: 12px; }
  .search { max-width: none; }
  .doc-header h1 { font-size: 28px; }
  .doc-body h2 { font-size: 22px; }
  .topic-card { flex: 0 0 240px; }
  .topic-group { margin-bottom: 32px; padding: 20px; }
}
  </style>
</head>
<body>
  <button id="go-to-top" title="Go to top">⬆</button>

  <header>
    <div class="header-inner">
      <div class="logo">⚡ AI-SDLC</div>
      <div class="search">
        <input type="text" id="searchInput" placeholder="Search docs..." />
        <div class="search-results" id="searchResults"></div>
      </div>
    </div>
  </header>

  <main>
    ${groupBlocks}
    ${docCards}
  </main>

  <script>
    // Go to top button
    const goToTopBtn = document.getElementById('go-to-top');

    window.addEventListener('scroll', () => {
      if (window.scrollY > 300) {
        goToTopBtn.classList.add('visible');
      } else {
        goToTopBtn.classList.remove('visible');
      }
    });

    goToTopBtn.addEventListener('click', () => {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // Search
    const searchIndex = ${searchIndex};
    const searchInput = document.getElementById('searchInput');
    const searchResults = document.getElementById('searchResults');

    searchInput.addEventListener('input', (e) => {
      const query = e.target.value.toLowerCase();
      if (!query) {
        searchResults.classList.remove('active');
        return;
      }

      const results = searchIndex.filter(doc =>
        doc.title.toLowerCase().includes(query) ||
        doc.content.toLowerCase().includes(query)
      ).slice(0, 8);

      if (results.length === 0) {
        searchResults.innerHTML = '<div class="search-result-item">No results</div>';
      } else {
        searchResults.innerHTML = results.map(r => \`
          <a href="#\${r.slug}" class="search-result-item">
            <div class="search-result-title">\${r.title}</div>
            <div class="search-result-snippet">\${r.content.substring(0, 80)}...</div>
          </a>
        \`).join('');
      }

      searchResults.classList.add('active');
    });

    searchInput.addEventListener('blur', () => {
      setTimeout(() => searchResults.classList.remove('active'), 200);
    });

    // Prism
    function initPrism() {
      if (typeof Prism !== 'undefined') {
        Prism.highlightAll();
      }
      if (typeof mermaid !== 'undefined') {
        mermaid.contentLoaded();
      }
    }

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', initPrism);
    } else {
      initPrism();
    }

    setTimeout(initPrism, 100);
  </script>
</body>
</html>`;
}

function main() {
  const docs = loadDocs();
  const html = buildHTML(docs);
  const hash = calculateHash(html);

  const oldHash = fs.existsSync(HASH_FILE) ? fs.readFileSync(HASH_FILE, 'utf8').trim() : null;
  if (hash === oldHash) {
    console.log(`✓ No changes detected`);
    return;
  }

  fs.writeFileSync(OUT, html);
  fs.writeFileSync(HASH_FILE, hash);

  const size = (fs.statSync(OUT).size / 1024).toFixed(1);
  console.log(`Generated ${OUT} (v7.5.0, ${docs.length} sections, ${size} KB)`);
}

main();
