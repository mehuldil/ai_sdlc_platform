#!/usr/bin/env node
/**
 * User_Manual/build-manual-html.mjs
 * ----------------------------------
 * Single-file offline manual generator.
 *
 * Reads every Markdown file listed in ORDER plus User_Manual/VERSION,
 * packs them as a JSON payload, and emits a self-contained
 * User_Manual/manual.html that renders Markdown on-the-fly
 * using the bundled manual-client.js.
 *
 * Usage:
 *   node User_Manual/build-manual-html.mjs            # regenerate manual.html
 *   node User_Manual/build-manual-html.mjs --check    # exit 1 on drift (for CI)
 *
 * v2.1.1 rewrite: clean, self-contained, CI-friendly. No external deps.
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const UM = __dirname;
const OUT = path.join(UM, "manual.html");

/* ------------------------------------------------------------------ */
/* Reading order (= sidebar order).                                    */
/* Concept → install → practice → mechanics → integrations → ops →     */
/* legacy → FAQ.                                                       */
/* ------------------------------------------------------------------ */
const ORDER = [
  "README.md",
  "INDEX.md",
  "System_Overview.md",
  "Prerequisites.md",
  "Getting_Started.md",
  "CANONICAL_REPO_AND_INTERFACES.md",
  "Happy_Path_End_to_End.md",
  "SDLC_Flows.md",
  "Role_and_Stage_Playbook.md",
  "FEATURES_REFERENCE.md",
  "Commands.md",
  "Guided_Execution_and_Recovery.md",
  "Persistent_Memory.md",
  "ADO_MCP_Integration.md",
  "Agents_Skills_Rules.md",
  "Architecture.md",
  "../docs/sdlc-stage-role-mapping.md",
  "Token_Efficiency_and_Context_Loading.md",
  "Repository_Complexity_Explained.md",
  "PR_Merge_Process.md",
  "Enforcement_Contract.md",
  "Traceability_and_Governance.md",
  "Platform_Extension_Onboarding.md",
  "Team_Onboarding_Presentation.md",
  "Documentation_Rules.md",
  "Migrating_From_V1_to_V2.md",
  "Migrating_From_V2_to_V2.1.md",
  "Migrating_From_V2_to_Current.md",
  "V2_Improvements_Over_V1.md",
  "FAQ.md",
  "CHANGELOG.md",
];

const TITLES = {
  "README.md": "Home",
  "INDEX.md": "Index & reading guide",
  "FEATURES_REFERENCE.md": "Features — how they work",
  "ADO_MCP_Integration.md": "ADO & MCP integration",
  "PR_Merge_Process.md": "PR & merge process",
  "SDLC_Flows.md": "SDLC flows",
  "CANONICAL_REPO_AND_INTERFACES.md": "Canonical repo & interfaces",
};

/* ------------------------------------------------------------------ */
function titleFor(name) {
  if (TITLES[name]) return TITLES[name];
  return name.replace(/\.md$/, "").replace(/_/g, " ");
}
function slugFor(name) {
  return name
    .replace(/\.md$/, "")
    .replace(/^.*[\\/]/, "")  // Strip any path prefix (e.g., ../docs/)
    .toLowerCase();
}
function esc(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/* ------------------------------------------------------------------ */
function loadDocs() {
  const docs = [];
  const missing = [];
  for (const f of ORDER) {
    const p = path.join(UM, f);
    if (!fs.existsSync(p)) {
      missing.push(f);
      continue;
    }
    const markdown = fs.readFileSync(p, "utf8");
    const headers = extractHeaders(markdown);

    docs.push({
      file: f,
      slug: slugFor(f),
      title: titleFor(f),
      markdown: markdown,
      headers: headers,
    });
  }
  return { docs, missing };
}

function readVersion() {
  // Try VERSION file first (backward compatibility)
  const versionFile = path.join(UM, "VERSION");
  if (fs.existsSync(versionFile)) {
    const raw = fs.readFileSync(versionFile, "utf8").replace(/^\uFEFF/, "").trim();
    if (/\u0000/.test(raw)) {
      return raw.replace(/\u0000/g, "").trim();
    }
    if (raw && raw !== "0.0.0") return raw;
  }

  // Auto-detect from CHANGELOG.md header
  const changelogPath = path.join(UM, "CHANGELOG.md");
  if (fs.existsSync(changelogPath)) {
    const content = fs.readFileSync(changelogPath, "utf8");
    // Match ## [2.1.4] format
    const match = content.match(/##\s*\[(\d+\.\d+\.\d+)\]/);
    if (match) return match[1];
  }

  return "0.0.0";
}

function readClient() {
  const p = path.join(UM, "manual-client.js");
  if (!fs.existsSync(p)) {
    throw new Error("manual-client.js not found in " + UM);
  }
  return fs.readFileSync(p, "utf8");
}

function readPrismJS() {
  // Read and concatenate Prism core + components
  const files = [
    "prism-core.js",
    "prism-bash.js",
    "prism-javascript.js",
    "prism-python.js",
    "prism-json.js",
    "prism-yaml.js"
  ];
  let code = "";
  for (const f of files) {
    const p = path.join(UM, f);
    if (fs.existsSync(p)) {
      code += fs.readFileSync(p, "utf8") + "\n";
    }
  }
  return code;
}

function readPrismCSS() {
  const p = path.join(UM, "prism-tomorrow.css");
  if (!fs.existsSync(p)) return "";
  return fs.readFileSync(p, "utf8");
}

function extractHeaders(markdown) {
  // Extract headers (# ## ###) from markdown for TOC
  const headers = [];
  const lines = markdown.split("\n");
  for (const line of lines) {
    const match = line.match(/^(#{1,3})\s+(.+)$/);
    if (match) {
      const level = match[1].length;
      const text = match[2].replace(/\s*#+\s*$/, "").trim(); // Remove trailing hashes
      const anchor = text.toLowerCase()
        .replace(/[^\w\s-]/g, "")
        .replace(/\s+/g, "-")
        .substring(0, 50);
      headers.push({ level, text, anchor });
    }
  }
  return headers;
}

function buildSearchIndex(docs) {
  // Build inverted index for full-text search
  const index = new Map();
  const docWordPositions = new Map(); // Track positions for highlighting

  for (const doc of docs) {
    const slug = doc.slug;
    const content = doc.markdown.toLowerCase();

    // Extract words (3+ chars, alphanumeric)
    const words = content.match(/\b[a-z][a-z0-9]{2,}\b/g) || [];

    // Track word frequencies and positions
    const wordFreq = new Map();
    const wordPositions = new Map();

    for (let i = 0; i < words.length; i++) {
      const word = words[i];

      // Skip common stop words
      if (stopWords.has(word)) continue;

      // Track frequency
      wordFreq.set(word, (wordFreq.get(word) || 0) + 1);

      // Track positions
      if (!wordPositions.has(word)) wordPositions.set(word, []);
      wordPositions.get(word).push(i);

      // Add to global index
      if (!index.has(word)) index.set(word, new Set());
      index.get(word).add(slug);
    }

    // Store per-doc word data
    docWordPositions.set(slug, {
      frequencies: Object.fromEntries(wordFreq),
      positions: Object.fromEntries(
        Array.from(wordPositions.entries()).map(([k, v]) => [k, v.slice(0, 10)]) // Limit positions
      )
    });
  }

  // Convert Sets to Arrays for JSON serialization
  const serializableIndex = {};
  for (const [word, slugs] of index) {
    serializableIndex[word] = Array.from(slugs);
  }

  return {
    index: serializableIndex,
    docData: Object.fromEntries(docWordPositions)
  };
}

// Common English stop words to exclude from search index
const stopWords = new Set([
  "the", "and", "for", "are", "but", "not", "you", "all", "can", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "man", "new", "now", "old", "see", "two", "way", "who", "boy", "did", "its", "let", "put", "say", "she", "too", "use", "with", "have", "this", "will", "your", "from", "they", "know", "want", "been", "good", "much", "some", "time", "very", "when", "come", "here", "just", "like", "long", "make", "many", "over", "such", "take", "than", "them", "well", "were", "what", "look", "more", "only", "other", "after", "back", "call", "came", "come", "could", "down", "find", "first", "give", "into", "little", "make", "most", "must", "never", "next", "only", "over", "said", "should", "some", "sound", "still", "such", "take", "than", "that", "their", "them", "then", "there", "these", "they", "thing", "this", "those", "through", "time", "very", "want", "water", "went", "were", "what", "when", "where", "which", "while", "white", "will", "with", "work", "would", "write", "year", "you", "about"
]);

/* ------------------------------------------------------------------ */
/* HTML shell                                                          */
/* ------------------------------------------------------------------ */

// Prism CSS for syntax highlighting (injected after main CSS)
const PRISM_CSS_ADDITION = `
/* Prism.js tomorrow night theme - customized for dark mode */
code[class*="language-"],
pre[class*="language-"] {
  color: #ccc;
  background: none;
  font-family: Consolas, Monaco, 'Andale Mono', 'Ubuntu Mono', monospace;
  font-size: 0.9em;
  text-align: left;
  white-space: pre;
  word-spacing: normal;
  word-break: normal;
  word-wrap: normal;
  line-height: 1.5;
  tab-size: 4;
  hyphens: none;
}

pre[class*="language-"] {
  padding: 1em;
  margin: 0.5em 0;
  overflow: auto;
  background: #0a0a0c;
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 8px;
}

:not(pre) > code[class*="language-"] {
  padding: 0.1em 0.3em;
  border-radius: 0.3em;
  background: rgba(255,255,255,0.1);
  white-space: normal;
}

.token.comment,
.token.block-comment,
.token.prolog,
.token.doctype,
.token.cdata {
  color: #999;
}

.token.punctuation {
  color: #ccc;
}

.token.tag,
.token.attr-name,
.token.namespace,
.token.deleted {
  color: #e2777a;
}

.token.function-name {
  color: #6196cc;
}

.token.boolean,
.token.number,
.token.function {
  color: #f08d49;
}

.token.property,
.token.class-name,
.token.constant,
.token.symbol {
  color: #f8c555;
}

.token.selector,
.token.important,
.token.atrule,
.token.keyword,
.token.builtin {
  color: #cc99cd;
}

.token.string,
.token.char,
.token.attr-value,
.token.regex,
.token.variable {
  color: #7ec699;
}

.token.operator,
.token.entity,
.token.url {
  color: #67cdcc;
}

.token.important,
.token.bold {
  font-weight: bold;
}

.token.italic {
  font-style: italic;
}

.token.entity {
  cursor: help;
}

.token.inserted {
  color: green;
}
`;

const CSS = `
:root {
  --space: 8px;
  --bg-base: #0c0c0e;
  --bg-glass: rgba(28, 28, 32, 0.72);
  --bg-card: rgba(255, 255, 255, 0.035);
  --bg-code: #0a0a0c;
  --text-primary: rgba(255, 255, 255, 0.92);
  --text-secondary: rgba(255, 255, 255, 0.52);
  --text-tertiary: rgba(255, 255, 255, 0.36);
  --accent: #0a84ff;
  --accent-soft: rgba(10, 132, 255, 0.14);
  --accent-glow: rgba(10, 132, 255, 0.22);
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.35);
  --shadow-md: 0 8px 32px rgba(0, 0, 0, 0.45);
  --shadow-diffuse: 0 24px 80px -20px rgba(0, 0, 0, 0.55);
  --radius-lg: 16px;
  --radius-md: 12px;
  --radius-sm: 8px;
  --ease: cubic-bezier(0.25, 0.1, 0.25, 1);
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --font: "Inter", -apple-system, BlinkMacSystemFont, "SF Pro Text", system-ui, sans-serif;
  --reading-width: 760px;
  --header-h: 56px;
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}

* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
@media (prefers-reduced-motion: reduce) { html { scroll-behavior: auto; } }

body {
  margin: 0;
  min-height: 100vh;
  font-family: var(--font);
  font-size: 16px;
  line-height: 1.65;
  color: var(--text-primary);
  overflow-wrap: anywhere;
  word-wrap: break-word;
  background: var(--bg-base);
  background-image:
    radial-gradient(ellipse 120% 80% at 50% -20%, rgba(10, 132, 255, 0.06), transparent 50%),
    radial-gradient(ellipse 80% 50% at 100% 100%, rgba(88, 86, 214, 0.04), transparent 45%);
  -webkit-font-smoothing: antialiased;
}
body.spotlight-open { overflow: hidden; }

a { color: var(--accent); text-decoration: none; transition: color 0.2s var(--ease); }
a:hover { color: #409cff; }

#content, .reading-column, .doc-card, .doc-card-body, .doc-card-body .md-inner { min-width: 0; }

.app {
  display: grid;
  grid-template-columns: 280px 1fr;
  min-height: 100vh;
  gap: calc(var(--space) * 3);
  padding: calc(var(--space) * 3);
  max-width: 1400px;
  margin: 0 auto;
}
@media (max-width: 1024px) {
  .app { grid-template-columns: 1fr; padding: calc(var(--space) * 2); }
  .sidebar-dock { position: relative; top: auto; max-height: none; }
}

.sidebar-dock {
  position: sticky;
  top: calc(var(--space) * 3);
  align-self: start;
  max-height: calc(100vh - calc(var(--space) * 6));
  overflow: hidden;
}
.sidebar-panel {
  display: flex;
  flex-direction: column;
  gap: calc(var(--space) * 2);
  padding: calc(var(--space) * 2.5);
  border-radius: var(--radius-lg);
  background: var(--bg-glass);
  backdrop-filter: blur(40px) saturate(180%);
  -webkit-backdrop-filter: blur(40px) saturate(180%);
  box-shadow: var(--shadow-md), inset 0 1px 0 rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.06);
  overflow-y: auto;
  max-height: calc(100vh - calc(var(--space) * 6));
}
.brand-mark {
  padding-bottom: calc(var(--space) * 2);
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}
.brand-mark h1 {
  margin: 0; font-size: 13px; font-weight: 600;
  letter-spacing: -0.01em; color: var(--text-primary);
}
.brand-mark .ver {
  margin-top: 6px; font-size: 11px; font-weight: 500;
  color: var(--text-tertiary); letter-spacing: 0.02em;
}
.nav-label {
  font-size: 10px; font-weight: 600; letter-spacing: 0.12em;
  text-transform: uppercase; color: var(--text-tertiary);
  margin: calc(var(--space) * 1.5) 0 calc(var(--space) * 0.75);
  padding-left: 2px;
}
#nav { display: flex; flex-direction: column; gap: 2px; }
.nav-pill {
  display: flex; align-items: center; gap: 10px;
  padding: 8px 12px; border-radius: 999px;
  font-size: 13px; font-weight: 450;
  color: var(--text-secondary); text-decoration: none;
  border: none; background: transparent; cursor: pointer;
  transition: background 0.25s var(--ease), color 0.25s var(--ease), transform 0.2s var(--ease-out);
}
.nav-pill:hover { background: rgba(255, 255, 255, 0.06); color: var(--text-primary); transform: translateX(2px); }
.nav-pill.active {
  color: var(--text-primary);
  background: linear-gradient(135deg, var(--accent-soft), rgba(255, 255, 255, 0.05));
  box-shadow: 0 0 0 1px rgba(10, 132, 255, 0.25), 0 4px 20px var(--accent-glow);
}
.nav-pill-icon {
  width: 6px; height: 6px; border-radius: 50%;
  background: rgba(255, 255, 255, 0.2); flex-shrink: 0;
  transition: background 0.25s var(--ease);
}
.nav-pill.active .nav-pill-icon { background: var(--accent); box-shadow: 0 0 10px var(--accent-glow); }
.nav-pill-label { flex: 1; min-width: 0; overflow-wrap: anywhere; word-break: break-word; }
.nav-pill.hidden { display: none; }

.main-shell { min-width: 0; display: flex; flex-direction: column; }
.app-header {
  position: sticky; top: 0; z-index: 40;
  margin: calc(var(--space) * -1.5) calc(var(--space) * -2) calc(var(--space) * 2);
  padding: calc(var(--space) * 1.5) calc(var(--space) * 2);
  min-height: var(--header-h);
  display: flex; flex-direction: column; gap: calc(var(--space) * 1);
  border-radius: 0 0 var(--radius-lg) var(--radius-lg);
  transition: background 0.35s var(--ease), backdrop-filter 0.35s var(--ease), box-shadow 0.35s var(--ease);
}
.app-header.is-scrolled {
  background: rgba(12, 12, 14, 0.75);
  backdrop-filter: blur(24px) saturate(160%);
  -webkit-backdrop-filter: blur(24px) saturate(160%);
  box-shadow: 0 8px 40px rgba(0, 0, 0, 0.35), inset 0 -1px 0 rgba(255, 255, 255, 0.05);
}
.header-row {
  display: flex; align-items: center; gap: calc(var(--space) * 1.5);
  flex-wrap: wrap; width: 100%;
  min-height: calc(var(--header-h) - 8px);
}
.search-field { flex: 1; min-width: 200px; max-width: 420px; position: relative; }
.search-field kbd {
  position: absolute; right: 12px; top: 50%;
  transform: translateY(-50%);
  font-size: 10px; font-family: inherit; font-weight: 500;
  padding: 2px 6px; border-radius: 4px;
  color: var(--text-tertiary);
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.08);
  pointer-events: none;
}
.search-field input {
  width: 100%; padding: 11px 52px 11px 16px;
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(255, 255, 255, 0.05);
  color: var(--text-primary); font-size: 14px;
  font-family: inherit; outline: none;
  transition: border-color 0.25s var(--ease), background 0.25s var(--ease), box-shadow 0.25s var(--ease);
}
.search-field input::placeholder { color: var(--text-tertiary); }
.search-field input:focus {
  border-color: rgba(10, 132, 255, 0.45);
  background: rgba(255, 255, 255, 0.07);
  box-shadow: 0 0 0 4px var(--accent-soft);
}
#search-status {
  width: 100%; font-size: 12px; color: var(--text-tertiary);
  margin-top: 8px; padding-left: 4px; min-height: 1.2em;
  overflow-wrap: anywhere;
}
#search-status:empty { display: none; }
.header-actions { display: flex; align-items: center; gap: 8px; margin-left: auto; }
.btn-ghost {
  padding: 8px 14px; border-radius: 999px;
  font-size: 12px; font-weight: 500;
  color: var(--text-secondary);
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.08);
  cursor: pointer; font-family: inherit;
  transition: background 0.2s var(--ease), transform 0.2s var(--ease-out);
}
.btn-ghost:hover {
  background: rgba(255, 255, 255, 0.09);
  color: var(--text-primary);
  transform: translateY(-1px);
}
.jump-select {
  padding: 8px 12px; border-radius: var(--radius-sm);
  font-size: 12px; font-family: inherit;
  color: var(--text-secondary);
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.08);
  cursor: pointer; max-width: 180px; outline: none;
  transition: border-color 0.2s var(--ease);
}
.jump-select:focus { border-color: rgba(10, 132, 255, 0.4); }

.reading-column {
  flex: 1; width: 100%;
  max-width: var(--reading-width);
  margin: 0 auto; padding: 0 8px calc(var(--space) * 8);
  overflow-wrap: anywhere;
}
#search-empty {
  text-align: center;
  padding: calc(var(--space) * 8) calc(var(--space) * 3);
  color: var(--text-tertiary);
  font-size: 15px; font-weight: 450;
}
#search-empty[hidden] { display: none !important; }

.doc-card {
  scroll-margin-top: calc(var(--header-h) + 16px);
  margin-bottom: calc(var(--space) * 3);
  border-radius: var(--radius-md);
  background: var(--bg-card);
  border: 1px solid rgba(255, 255, 255, 0.05);
  box-shadow: var(--shadow-sm), var(--shadow-diffuse);
  overflow-x: hidden; overflow-y: visible;
  transition: transform 0.3s var(--ease-out), box-shadow 0.3s var(--ease);
}
.doc-card:hover {
  transform: translateY(-1px);
  box-shadow: var(--shadow-md), 0 20px 60px -30px rgba(0, 0, 0, 0.5);
}
@media (prefers-reduced-motion: reduce) { .doc-card:hover { transform: none; } }

.doc-card-toggle {
  width: 100%; min-width: 0;
  display: flex; align-items: flex-start; justify-content: space-between;
  gap: 16px;
  padding: calc(var(--space) * 2.25) calc(var(--space) * 2.5);
  margin: 0; border: none;
  background: rgba(255, 255, 255, 0.02);
  cursor: pointer; font-family: inherit;
  text-align: left; color: inherit;
  transition: background 0.25s var(--ease);
}
.doc-card-toggle:hover { background: rgba(255, 255, 255, 0.04); }
.doc-card-title {
  flex: 1 1 auto; min-width: 0;
  font-size: 22px; font-weight: 600;
  letter-spacing: -0.02em; line-height: 1.35;
  overflow-wrap: anywhere; word-break: break-word;
}
.doc-card-chevron {
  width: 10px; height: 10px;
  border-right: 2px solid var(--text-tertiary);
  border-bottom: 2px solid var(--text-tertiary);
  transform: rotate(45deg);
  transition: transform 0.3s var(--ease-out);
  flex-shrink: 0; margin-top: 6px; margin-bottom: 4px;
}
.doc-card.collapsed .doc-card-chevron { transform: rotate(-135deg); margin-bottom: 0; }

.doc-card-body {
  display: grid;
  grid-template-rows: 1fr;
  transition: grid-template-rows 0.35s var(--ease-out), opacity 0.3s var(--ease);
}
.doc-card.collapsed .doc-card-body {
  grid-template-rows: 0fr; opacity: 0; pointer-events: none;
}
.doc-card.collapsed .doc-card-body .md-inner { overflow: hidden; min-height: 0; }
.doc-card-body .md-inner {
  min-height: 0;
  padding: 4px calc(var(--space) * 2.5) calc(var(--space) * 3);
  overflow-wrap: anywhere; word-break: break-word;
}
.md-inner .md-h1 { font-size: clamp(28px, 4vw, 34px); font-weight: 600; letter-spacing: -0.03em; line-height: 1.25; margin: 0 0 24px; color: var(--text-primary); }
.md-inner .md-h2 { font-size: 24px; font-weight: 600; letter-spacing: -0.02em; margin: 40px 0 14px; line-height: 1.3; color: rgba(255,255,255,0.88); }
.md-inner .md-h3 { font-size: 18px; font-weight: 600; margin: 28px 0 10px; letter-spacing: -0.015em; color: rgba(255,255,255,0.85); }
.md-inner .md-h4 { font-size: 15px; font-weight: 600; margin: 22px 0 8px; color: rgba(255,255,255,0.8); }
.md-inner p { margin: 0 0 16px; color: var(--text-secondary); }
.md-inner ul, .md-inner ol { margin: 0 0 16px; padding-left: 1.35em; color: var(--text-secondary); }
.md-inner li { margin: 6px 0; }
.md-inner strong { color: rgba(255,255,255,0.88); font-weight: 600; }
.md-inner code {
  font-family: "SF Mono", ui-monospace, "Cascadia Code", monospace;
  font-size: 0.88em;
  padding: 3px 7px; border-radius: 6px;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.06);
  color: rgba(255, 255, 255, 0.88);
  overflow-wrap: anywhere; word-break: break-word;
}
.code-block-wrap {
  position: relative; margin: 20px 0;
  border-radius: var(--radius-md);
  background: var(--bg-code);
  border: 1px solid rgba(255, 255, 255, 0.07);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04);
}
.code-block-wrap .md-pre {
  margin: 0; padding: 18px;
  overflow-x: auto;
  font-size: 13px; line-height: 1.55;
}
.code-block-wrap .md-pre code {
  border: none; padding: 0; background: none;
  font-size: inherit; color: rgba(255, 255, 255, 0.75);
}
.code-copy-btn {
  position: absolute; top: 10px; right: 10px;
  padding: 5px 10px;
  font-size: 11px; font-weight: 500; font-family: inherit;
  color: var(--text-tertiary);
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 6px; cursor: pointer;
  opacity: 0;
  transition: opacity 0.2s var(--ease);
}
.code-block-wrap:hover .code-copy-btn, .code-copy-btn:focus { opacity: 1; }
.code-copy-btn:hover { color: var(--text-primary); background: rgba(255, 255, 255, 0.1); }

.table-wrap {
  margin: 20px 0;
  border-radius: var(--radius-sm);
  overflow-x: auto;
  border: 1px solid rgba(255, 255, 255, 0.06);
  max-width: 100%;
}
.md-table {
  width: 100%; max-width: 100%;
  border-collapse: collapse;
  font-size: 14px; table-layout: fixed;
}
.md-table th, .md-table td {
  padding: 10px 14px; text-align: left;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  vertical-align: top;
  overflow-wrap: anywhere; word-break: break-word; hyphens: auto;
}
.md-table th {
  font-size: 12px; font-weight: 600;
  text-transform: uppercase; letter-spacing: 0.04em;
  color: var(--text-tertiary);
  background: rgba(255, 255, 255, 0.03);
}
.md-table td { color: var(--text-secondary); }
.md-table tr:last-child td { border-bottom: none; }
.md-hr {
  border: none; height: 1px; margin: 36px 0;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.08), transparent);
}
.md-quote {
  margin: 20px 0; padding: 14px 18px;
  border-left: 3px solid rgba(10, 132, 255, 0.5);
  background: rgba(10, 132, 255, 0.06);
  border-radius: 0 var(--radius-sm) var(--radius-sm) 0;
}
.md-quote p { margin: 0; color: var(--text-secondary); font-size: 15px; }
mark.manual-hit {
  background: rgba(255, 214, 10, 0.25);
  color: rgba(255, 255, 255, 0.95);
  padding: 1px 3px; border-radius: 4px;
}

.site-footer {
  margin-top: calc(var(--space) * 6);
  padding-top: calc(var(--space) * 3);
  border-top: 1px solid rgba(255, 255, 255, 0.06);
  font-size: 12px; color: var(--text-tertiary);
  line-height: 1.6;
}
.site-footer code {
  font-size: 11px; padding: 2px 6px;
  border-radius: 4px;
  background: rgba(255, 255, 255, 0.05);
}

.spotlight {
  position: fixed; inset: 0; z-index: 100;
  display: grid; place-items: flex-start center;
  padding-top: 12vh;
  background: rgba(0, 0, 0, 0.55);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  animation: spotlightIn 0.28s var(--ease-out);
}
.spotlight[hidden] { display: none !important; }
@keyframes spotlightIn { from { opacity: 0; } to { opacity: 1; } }
.spotlight-panel {
  width: min(560px, 92vw);
  padding: 10px;
  border-radius: var(--radius-lg);
  background: rgba(22, 22, 26, 0.95);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: var(--shadow-diffuse), 0 0 0 1px rgba(255, 255, 255, 0.05) inset;
}
.spotlight-panel input {
  width: 100%; padding: 16px 18px;
  border-radius: var(--radius-md);
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(0, 0, 0, 0.35);
  color: var(--text-primary);
  font-size: 16px; font-family: inherit; outline: none;
}
.spotlight-panel input:focus {
  border-color: rgba(10, 132, 255, 0.5);
  box-shadow: 0 0 0 3px var(--accent-soft);
}
.spotlight-hint {
  margin-top: 12px; padding: 0 8px;
  font-size: 12px; color: var(--text-tertiary);
  display: flex; justify-content: space-between; align-items: center;
  gap: 8px;
}
.spotlight-close {
  background: none; border: none;
  color: var(--text-tertiary);
  font-size: 12px; cursor: pointer; font-family: inherit;
}
.spotlight-close:hover { color: var(--text-primary); }
`;

/* ------------------------------------------------------------------ */
function buildHtml({ version, docs, clientJs, prismJs, searchIndex }) {
  const payload = JSON.stringify({ version, docs, searchIndex }).replace(/</g, "\\u003c");
  const encV = esc(version);
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="description" content="AI-SDLC Platform — interactive offline user manual (v${encV})" />
  <meta name="generator" content="User_Manual/build-manual-html.mjs v2.1.4" />
  <meta name="theme-color" content="#0c0c0e" />
  <title>AI-SDLC User Manual · v${encV}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,400..600;1,14..32,400..600&display=swap" rel="stylesheet" />
  <style>${CSS}${PRISM_CSS_ADDITION}</style>
</head>
<body>
  <div class="app">
    <div class="sidebar-dock">
      <aside class="sidebar-panel" aria-label="Manual navigation">
        <div class="brand-mark">
          <h1>AI-SDLC Manual</h1>
          <div class="ver">v${encV} · offline</div>
        </div>
        <div class="nav-label">Contents</div>
        <nav id="nav" aria-label="Pages"></nav>
        <div class="nav-label">Shortcuts</div>
        <nav class="quick-nav" aria-label="Shortcuts">
          <a class="nav-pill" href="#doc-faq"><span class="nav-pill-icon"></span><span class="nav-pill-label">FAQ</span></a>
          <a class="nav-pill" href="#doc-commands"><span class="nav-pill-icon"></span><span class="nav-pill-label">Commands</span></a>
          <a class="nav-pill" href="#doc-getting_started"><span class="nav-pill-icon"></span><span class="nav-pill-label">Getting started</span></a>
          <a class="nav-pill" href="#doc-changelog"><span class="nav-pill-icon"></span><span class="nav-pill-label">Changelog</span></a>
        </nav>
      </aside>
    </div>

    <div class="main-shell">
      <header class="app-header" id="app-header">
        <div class="header-row">
          <div class="search-field">
            <input type="search" id="q" placeholder="Search documentation…" autocomplete="off" aria-label="Search documentation" />
            <kbd>⌘K</kbd>
          </div>
          <div class="header-actions">
            <select id="jump-section" class="jump-select" aria-label="Jump to page">
              <option value="">Jump to page…</option>
            </select>
            <button type="button" class="btn-ghost" id="open-search">Spotlight</button>
          </div>
        </div>
        <div id="search-status" aria-live="polite"></div>
      </header>

      <div class="reading-column">
        <div id="search-empty" hidden>No pages match your search. Try different keywords.</div>
        <div id="content"></div>
        <footer class="site-footer">
          Generated from <code>User_Manual/*.md</code> (v${encV}) · Rebuild with <code>node User_Manual/build-manual-html.mjs</code> · Check drift: <code>--check</code>
        </footer>
      </div>
    </div>
  </div>

  <div id="spotlight" class="spotlight" hidden aria-hidden="true" role="dialog" aria-modal="true" aria-label="Search">
    <div class="spotlight-panel">
      <input type="search" id="q-spotlight" placeholder="Search…" autocomplete="off" aria-label="Spotlight search" />
      <div class="spotlight-hint">
        <span>Filters pages and highlights matches</span>
        <button type="button" class="spotlight-close" id="spotlight-close">Esc to close</button>
      </div>
    </div>
  </div>

  <script type="application/json" id="manual-data">${payload}</script>
  <script>
// Prism.js syntax highlighter
${prismJs}
// Client application
${clientJs}
  </script>
</body>
</html>
`;
}

/* ------------------------------------------------------------------ */
/* Main                                                                */
/* ------------------------------------------------------------------ */
function main() {
  const args = new Set(process.argv.slice(2));
  const checkMode = args.has("--check");

  const version = readVersion();
  const { docs, missing } = loadDocs();
  const clientJs = readClient();
  const prismJs = readPrismJS();
  const searchIndex = buildSearchIndex(docs);
  const html = buildHtml({ version, docs, clientJs, prismJs, searchIndex });

  if (missing.length) {
    console.warn(
      "⚠️  Skipped (not found): " + missing.join(", ")
    );
  }

  if (checkMode) {
    const existing = fs.existsSync(OUT) ? fs.readFileSync(OUT, "utf8") : "";
    if (existing === html) {
      console.log(`✓ manual.html is up to date (v${version}, ${docs.length} pages)`);
      process.exit(0);
    }
    console.error(
      `✗ manual.html is stale. Rebuild with:\n    node User_Manual/build-manual-html.mjs`
    );
    process.exit(1);
  }

  fs.writeFileSync(OUT, html, "utf8");
  console.log(
    `✓ Generated manual.html (v${version}, ${docs.length} pages, ${(
      Buffer.byteLength(html, "utf8") / 1024
    ).toFixed(1)} KB)`
  );
}

main();
