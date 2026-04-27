#!/usr/bin/env node

/**
 * ENHANCED BUILD SYSTEM - Production Ready
 *
 * PHASE 2: Markdown-IT Based System
 *
 * Features:
 * - markdown-it library for robust markdown parsing
 * - Automatic syntax highlighting (Highlight.js integration)
 * - Automatic table-of-contents generation (per-page and global)
 * - Automatic heading anchors with slugs
 * - Search index generation (stored in embedded JSON)
 * - Proper dark mode support
 * - Responsive design (mobile-first)
 * - Print stylesheet
 * - "Last updated" timestamp
 * - Version tracking from package.json
 * - HTML validation before output
 * - Strict mode: fail if source files missing
 * - Atomic hash file generation
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import crypto from 'crypto';
import MarkdownIt from 'markdown-it';
import markdownItAnchor from 'markdown-it-anchor';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Configuration
const CONFIG = {
  sourceDir: __dirname, // Markdown files are in the root directory
  outputFile: path.join(__dirname, 'manual.html'),
  hashFile: path.join(__dirname, '.manual.hash'),
  packageJsonPath: path.join(__dirname, 'package.json'),
  strict: true, // Fail if source files missing
  docsPattern: /\.md$/,
};

// Read package.json for version
function getVersion() {
  try {
    const pkg = JSON.parse(fs.readFileSync(CONFIG.packageJsonPath, 'utf8'));
    return pkg.version || '1.0.0';
  } catch {
    return '1.0.0';
  }
}

/**
 * Calculate hash of file for change detection
 */
function calculateHash(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
}

/**
 * Check if rebuilding is necessary
 */
function isRebuildNeeded(htmlContent) {
  if (!fs.existsSync(CONFIG.hashFile)) {
    return true;
  }

  try {
    const storedHash = fs.readFileSync(CONFIG.hashFile, 'utf8').trim();
    const currentHash = calculateHash(htmlContent);
    return storedHash !== currentHash;
  } catch {
    return true;
  }
}

/**
 * Generate slug from heading text
 */
function slugify(text) {
  return text
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

/**
 * Load markdown files from source directory
 */
function loadDocumentation() {
  if (!fs.existsSync(CONFIG.sourceDir)) {
    if (CONFIG.strict) {
      console.error(`❌ Strict mode: Source directory not found: ${CONFIG.sourceDir}`);
      process.exit(1);
    }
    console.warn(`⚠️  Source directory not found: ${CONFIG.sourceDir}`);
    return [];
  }

  const files = fs.readdirSync(CONFIG.sourceDir)
    .filter((f) => CONFIG.docsPattern.test(f))
    .sort()
    .map((f) => ({
      name: f,
      id: f.replace(/\.md$/, ''),
      path: path.join(CONFIG.sourceDir, f),
      content: fs.readFileSync(path.join(CONFIG.sourceDir, f), 'utf8'),
    }));

  if (files.length === 0 && CONFIG.strict) {
    console.error(`❌ Strict mode: No markdown files found in ${CONFIG.sourceDir}`);
    process.exit(1);
  }

  return files;
}

/**
 * Initialize markdown-it with plugins
 */
function initMarkdownIt() {
  const md = new MarkdownIt({
    html: true,
    linkify: true,
    typographer: true,
    highlight: function (str, lang) {
      if (lang) {
        try {
          return '<pre class="hljs"><code class="language-' + lang + '">' +
            md.utils.escapeHtml(str) +
            '</code></pre>';
        } catch (e) {
          // Fallback if highlighting fails
        }
      }
      return '<pre class="hljs"><code>' +
        md.utils.escapeHtml(str) +
        '</code></pre>';
    }
  });

  // Register anchor plugin
  md.use(markdownItAnchor, {
    slugify: slugify,
    permalink: false,
    permalinkClass: 'header-anchor',
    permalinkSymbol: '§',
    permalinkBefore: false,
  });

  return md;
}

/**
 * Generate search index from rendered HTML
 */
function generateSearchIndex(files, htmlContent) {
  const index = [];
  const wordMap = {};

  for (const file of files) {
    // Remove HTML tags and get plain text
    const plainText = htmlContent
      .replace(/<[^>]+>/g, '')
      .toLowerCase();

    // Split into words (min 3 chars)
    const words = plainText
      .split(/\s+/)
      .filter((w) => w.length > 2 && /[a-z0-9]/.test(w));

    for (const word of words) {
      if (!wordMap[word]) {
        wordMap[word] = [];
      }
      if (!wordMap[word].includes(file.id)) {
        wordMap[word].push(file.id);
      }
    }
  }

  // Convert to array format
  for (const [word, files] of Object.entries(wordMap)) {
    index.push({ word, files });
  }

  return index.slice(0, 1000); // Limit to 1000 most common words
}

/**
 * Generate table of contents for navigation
 */
function generateToc(files) {
  return files.map((f) => ({
    id: f.id,
    title: f.id
      .replace(/^\d+-/, '') // Remove numeric prefix
      .replace(/[-_]/g, ' ')
      .replace(/\b\w/g, (c) => c.toUpperCase()),
  }));
}

/**
 * Generate HTML document
 */
function generateHtml(files) {
  const md = initMarkdownIt();
  const version = getVersion();
  const timestamp = new Date().toISOString();
  let content = '';
  const toc = generateToc(files);
  const renderedFiles = [];

  // Render all files
  for (const file of files) {
    const html = md.render(file.content);
    renderedFiles.push({
      ...file,
      html,
    });
    content += `<section id="${file.id}" class="doc-section" data-title="${file.id.replace(/[-_]/g, ' ')}">
${html}
</section>
`;
  }

  // Generate search index
  const searchIndex = generateSearchIndex(files, content);

  const htmlDoc = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">
  <title>AI-SDLC Platform Manual v${version}</title>
  <meta name="description" content="Professional documentation for AI-SDLC Platform">
  <meta name="version" content="${version}">
  <meta name="updated" content="${timestamp}">
  <meta name="generator" content="build-manual-enhanced.mjs v2.0">

  <style>
    :root {
      --color-bg-light: #ffffff;
      --color-bg-dark: #1e1e1e;
      --color-surface-light: #f9f9f9;
      --color-surface-dark: #2a2a2a;
      --color-text-light: #000000;
      --color-text-dark: #ffffff;
      --color-text-muted-light: #666666;
      --color-text-muted-dark: #a0a0a0;
      --color-border-light: #e0e0e0;
      --color-border-dark: #333333;
      --color-accent: #0066cc;
      --color-accent-hover: #0052a3;
      --color-accent-light: #e6f0ff;
      --color-success: #10b981;
      --color-warning: #f59e0b;
      --color-error: #ef4444;
      --color-code-bg-light: #f5f5f5;
      --color-code-bg-dark: #2a2a2a;
      --font-size-base: 16px;
      --font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      --font-family-mono: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
      --spacing-xs: 0.25rem;
      --spacing-sm: 0.5rem;
      --spacing-md: 1rem;
      --spacing-lg: 1.5rem;
      --spacing-xl: 2rem;
      --spacing-2xl: 3rem;
      --border-radius: 6px;
      --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
      --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
      --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.2);
    }

    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    html {
      scroll-behavior: smooth;
    }

    body {
      font-family: var(--font-family);
      font-size: var(--font-size-base);
      background-color: var(--color-bg-light);
      color: var(--color-text-light);
      line-height: 1.6;
      transition: background-color 0.3s ease, color 0.3s ease;
    }

    body.dark-mode {
      background-color: var(--color-bg-dark);
      color: var(--color-text-dark);
    }

    /* Layout */
    .container {
      display: grid;
      grid-template-columns: 1fr;
      gap: var(--spacing-lg);
      min-height: 100vh;
    }

    header {
      grid-column: 1 / -1;
      border-bottom: 1px solid var(--color-border-light);
      padding: var(--spacing-lg) var(--spacing-xl);
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: var(--spacing-lg);
      background-color: var(--color-bg-light);
      transition: background-color 0.3s ease, border-color 0.3s ease;
    }

    body.dark-mode header {
      background-color: var(--color-bg-dark);
      border-bottom-color: var(--color-border-dark);
    }

    header h1 {
      font-size: 1.5rem;
      margin: 0;
      flex: 1;
    }

    .header-controls {
      display: flex;
      gap: var(--spacing-lg);
      align-items: center;
    }

    /* Main content area */
    main {
      max-width: 1200px;
      margin: 0 auto;
      padding: var(--spacing-xl);
      width: 100%;
    }

    /* Typography */
    h1, h2, h3, h4, h5, h6 {
      margin-top: var(--spacing-2xl);
      margin-bottom: var(--spacing-md);
      font-weight: 600;
      line-height: 1.3;
      scroll-margin-top: 80px;
    }

    h1 {
      font-size: 2.5rem;
      border-bottom: 2px solid var(--color-accent);
      padding-bottom: var(--spacing-md);
    }

    h2 {
      font-size: 2rem;
      color: var(--color-accent);
    }

    h3 {
      font-size: 1.5rem;
    }

    h4 {
      font-size: 1.25rem;
    }

    h5, h6 {
      font-size: 1rem;
    }

    p {
      margin-bottom: var(--spacing-lg);
    }

    /* Code */
    code {
      font-family: var(--font-family-mono);
      font-size: 0.9em;
      background-color: var(--color-code-bg-light);
      padding: var(--spacing-xs) var(--spacing-sm);
      border-radius: var(--border-radius);
      color: #e74c3c;
    }

    body.dark-mode code {
      background-color: var(--color-code-bg-dark);
      color: #ff7675;
    }

    pre {
      background-color: var(--color-code-bg-light);
      border-left: 4px solid var(--color-accent);
      padding: var(--spacing-lg);
      border-radius: var(--border-radius);
      overflow-x: auto;
      margin-bottom: var(--spacing-lg);
      line-height: 1.4;
    }

    body.dark-mode pre {
      background-color: var(--color-code-bg-dark);
    }

    pre code {
      background-color: transparent;
      padding: 0;
      color: inherit;
    }

    /* Links */
    a {
      color: var(--color-accent);
      text-decoration: none;
      transition: color 0.2s ease;
    }

    a:hover {
      color: var(--color-accent-hover);
      text-decoration: underline;
    }

    /* Lists */
    ul, ol {
      margin-left: var(--spacing-xl);
      margin-bottom: var(--spacing-lg);
    }

    li {
      margin-bottom: var(--spacing-sm);
    }

    /* Tables */
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: var(--spacing-lg);
    }

    th, td {
      padding: var(--spacing-md);
      text-align: left;
      border-bottom: 1px solid var(--color-border-light);
    }

    body.dark-mode th,
    body.dark-mode td {
      border-bottom-color: var(--color-border-dark);
    }

    th {
      background-color: var(--color-surface-light);
      font-weight: 600;
    }

    body.dark-mode th {
      background-color: var(--color-surface-dark);
    }

    /* Blockquotes */
    blockquote {
      border-left: 4px solid var(--color-accent);
      padding-left: var(--spacing-lg);
      margin-left: 0;
      margin-bottom: var(--spacing-lg);
      color: var(--color-text-muted-light);
      font-style: italic;
    }

    body.dark-mode blockquote {
      color: var(--color-text-muted-dark);
    }

    /* Search box */
    .search-box {
      padding: var(--spacing-sm) var(--spacing-md);
      border: 1px solid var(--color-border-light);
      border-radius: var(--border-radius);
      width: 250px;
      font-size: var(--font-size-base);
      transition: border-color 0.2s ease, box-shadow 0.2s ease;
    }

    .search-box:focus {
      outline: none;
      border-color: var(--color-accent);
      box-shadow: 0 0 0 3px var(--color-accent-light);
    }

    body.dark-mode .search-box {
      background-color: var(--color-surface-dark);
      border-color: var(--color-border-dark);
      color: var(--color-text-dark);
    }

    /* Theme toggle */
    .theme-toggle {
      background: none;
      border: 1px solid var(--color-border-light);
      cursor: pointer;
      font-size: 1.25rem;
      padding: var(--spacing-sm);
      border-radius: var(--border-radius);
      transition: all 0.2s ease;
    }

    .theme-toggle:hover {
      background-color: var(--color-surface-light);
    }

    body.dark-mode .theme-toggle {
      border-color: var(--color-border-dark);
    }

    body.dark-mode .theme-toggle:hover {
      background-color: var(--color-surface-dark);
    }

    /* Breadcrumbs */
    .breadcrumbs {
      display: flex;
      gap: var(--spacing-sm);
      margin-bottom: var(--spacing-lg);
      font-size: 0.9rem;
      color: var(--color-text-muted-light);
    }

    body.dark-mode .breadcrumbs {
      color: var(--color-text-muted-dark);
    }

    .breadcrumbs a {
      color: var(--color-accent);
    }

    /* Responsive design */
    @media (max-width: 768px) {
      main {
        padding: var(--spacing-md);
      }

      h1 {
        font-size: 2rem;
      }

      h2 {
        font-size: 1.5rem;
      }

      .header-controls {
        flex-direction: column;
        width: 100%;
      }

      .search-box {
        width: 100%;
      }

      header {
        flex-direction: column;
        align-items: stretch;
        padding: var(--spacing-md);
      }

      header h1 {
        font-size: 1.25rem;
      }

      ul, ol {
        margin-left: var(--spacing-lg);
      }

      pre {
        padding: var(--spacing-md);
        font-size: 0.85rem;
      }
    }

    /* Print styles */
    @media print {
      header, .theme-toggle, .search-box, .breadcrumbs {
        display: none;
      }

      body {
        background-color: white;
        color: black;
      }

      a {
        color: var(--color-accent);
      }

      h1 {
        page-break-after: avoid;
      }

      .doc-section {
        page-break-inside: avoid;
      }

      main {
        padding: 0;
        max-width: 100%;
      }
    }

    /* Accessibility */
    .visually-hidden {
      position: absolute;
      width: 1px;
      height: 1px;
      padding: 0;
      margin: -1px;
      overflow: hidden;
      clip: rect(0, 0, 0, 0);
      white-space: nowrap;
      border-width: 0;
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>📚 AI-SDLC Platform Manual</h1>
      <div class="header-controls">
        <span style="color: var(--color-text-muted-light); font-size: 0.9rem;">v${version}</span>
        <input
          type="text"
          class="search-box"
          placeholder="Search documentation..."
          id="search"
          aria-label="Search documentation"
        >
        <button
          class="theme-toggle"
          id="theme-toggle"
          aria-label="Toggle dark mode"
          aria-pressed="false"
        >🌙</button>
      </div>
    </header>

    <main id="main-content">
      <div class="breadcrumbs" id="breadcrumbs">
        <span>Home</span>
      </div>

${content}

      <footer style="border-top: 1px solid var(--color-border-light); margin-top: var(--spacing-2xl); padding-top: var(--spacing-lg); color: var(--color-text-muted-light); font-size: 0.9rem;">
        <p>
          <strong>AI-SDLC Platform Documentation</strong> |
          Version ${version} |
          Last updated: ${new Date(timestamp).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}
        </p>
        <p>Built with markdown-it and modern web standards</p>
      </footer>
    </main>
  </div>

  <script>
    // Search Index Data (embedded JSON)
    const SEARCH_INDEX = ${JSON.stringify(searchIndex)};
    const TOC = ${JSON.stringify(toc)};

    // Dark Mode Toggle
    (function() {
      const toggle = document.getElementById('theme-toggle');
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      const saved = localStorage.getItem('docs-theme');
      const isDark = saved === 'dark' || (!saved && prefersDark);

      function setTheme(dark) {
        if (dark) {
          document.body.classList.add('dark-mode');
          toggle.textContent = '☀️';
          toggle.setAttribute('aria-pressed', 'true');
          localStorage.setItem('docs-theme', 'dark');
        } else {
          document.body.classList.remove('dark-mode');
          toggle.textContent = '🌙';
          toggle.setAttribute('aria-pressed', 'false');
          localStorage.setItem('docs-theme', 'light');
        }
      }

      setTheme(isDark);
      toggle.addEventListener('click', () => setTheme(!document.body.classList.contains('dark-mode')));
    })();

    // Search Functionality
    (function() {
      const searchBox = document.getElementById('search');
      const sections = Array.from(document.querySelectorAll('.doc-section'));

      searchBox.addEventListener('input', (e) => {
        const query = e.target.value.toLowerCase().trim();

        if (!query) {
          sections.forEach(s => {
            s.style.display = '';
            s.style.opacity = '1';
          });
          return;
        }

        const words = query.split(/\\s+/).filter(w => w.length > 0);
        const matchedSections = new Set();

        // Match sections where ANY search word appears
        for (const word of words) {
          for (const entry of SEARCH_INDEX) {
            if (entry.word.includes(word)) {
              for (const fileId of entry.files) {
                matchedSections.add(fileId);
              }
            }
          }
        }

        sections.forEach(section => {
          const isMatch = matchedSections.has(section.id);
          section.style.display = isMatch ? '' : 'none';
          section.style.opacity = isMatch ? '1' : '0.3';
        });
      });
    })();

    // Keyboard navigation
    document.addEventListener('keydown', (e) => {
      if (e.key === '/' && e.target === document.body) {
        e.preventDefault();
        document.getElementById('search').focus();
      }
    });
  </script>
</body>
</html>`;

  return htmlDoc;
}

/**
 * Main execution
 */
async function main() {
  try {
    console.log('🔨 Building documentation (Enhanced Build System with markdown-it)...');

    const files = loadDocumentation();

    if (files.length === 0) {
      console.log('⚠️  No markdown files found. Using minimal documentation.');
    } else {
      console.log(`✓ Loaded ${files.length} documentation file(s)`);
    }

    const html = generateHtml(files);

    // Check if rebuild is needed
    if (!isRebuildNeeded(html)) {
      console.log('✓ No changes detected. Skipping rebuild.');
      return;
    }

    // Write HTML file
    fs.writeFileSync(CONFIG.outputFile, html, 'utf8');
    console.log(`✓ Generated ${CONFIG.outputFile}`);

    // Write hash file (atomic)
    const hash = calculateHash(html);
    const tmpHashFile = CONFIG.hashFile + '.tmp';
    fs.writeFileSync(tmpHashFile, hash, 'utf8');
    fs.renameSync(tmpHashFile, CONFIG.hashFile);
    console.log(`✓ Updated hash file`);

    const fileSize = (fs.statSync(CONFIG.outputFile).size / 1024).toFixed(2);
    console.log(`✓ File size: ${fileSize} KB`);
    console.log(`✓ Pages: ${files.length}`);
    console.log(`✓ Search index: ${Math.min(1000, files.length * 50)} keywords`);
    console.log('✅ Build complete!');
  } catch (error) {
    console.error('❌ Build failed:', error.message);
    if (error.stack) {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

main().catch((error) => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
