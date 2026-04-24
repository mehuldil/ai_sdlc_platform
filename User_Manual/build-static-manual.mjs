import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const UM = __dirname;
const OUT = path.join(UM, "manual.html");

const ORDER = [
  "README.md", "INDEX.md", "System_Overview.md", "Prerequisites.md",
  "Getting_Started.md", "Repo_Layout.md", "Repo_Setup_Scenarios.md",
  "Happy_Path_End_to_End.md", "SDLC_Flows.md", "Role_and_Stage_Playbook.md",
  "FEATURES_REFERENCE.md", "Commands.md", "Guided_Execution_and_Recovery.md",
  "Persistent_Memory.md", "ADO_MCP_Integration.md", "Agents_Skills_Rules.md",
  "Architecture.md", "Token_Efficiency_and_Context_Loading.md",
  "PR_Merge_Process.md", "Platform_Extension_Onboarding.md",
  "Team_Onboarding.md", "Documentation_Rules.md", "FAQ.md", "CHANGELOG.md"
];

const TITLES = {
  "README.md": "🏠 Home",
  "INDEX.md": "📑 Index", 
  "System_Overview.md": "🌐 System Overview",
  "Prerequisites.md": "✅ Prerequisites",
  "Getting_Started.md": "🚀 Getting Started",
  "Repo_Layout.md": "📁 Repository Layout",
  "Repo_Setup_Scenarios.md": "📂 Repo Setup",
  "Happy_Path_End_to_End.md": "🎯 Happy Path",
  "SDLC_Flows.md": "🔄 SDLC Flows",
  "Role_and_Stage_Playbook.md": "🎭 Roles & Stages",
  "FEATURES_REFERENCE.md": "⭐ Features",
  "Commands.md": "⚡ Commands",
  "Guided_Execution_and_Recovery.md": "🔧 Recovery",
  "Persistent_Memory.md": "🧠 Memory",
  "ADO_MCP_Integration.md": "🔗 ADO",
  "Agents_Skills_Rules.md": "🤖 Agents",
  "Architecture.md": "🏗️ Architecture",
  "Token_Efficiency_and_Context_Loading.md": "💰 Token Efficiency",
  "PR_Merge_Process.md": "🔀 PR & Merge",
  "Platform_Extension_Onboarding.md": "📦 Extension",
  "Team_Onboarding.md": "👥 Team Onboarding",
  "Documentation_Rules.md": "📝 Doc Rules",
  "FAQ.md": "❓ FAQ",
  "CHANGELOG.md": "📋 Changelog"
};

function loadDocs() {
  const docs = [];
  for (const f of ORDER) {
    const p = path.join(UM, f);
    if (!fs.existsSync(p)) continue;
    const markdown = fs.readFileSync(p, "utf8").replace(/\u0000/g, "");
    docs.push({
      file: f,
      slug: f.replace(/\.md$/, "").toLowerCase().replace(/_/g, "-"),
      title: TITLES[f] || f.replace(/\.md$/, ""),
      simpleTitle: (TITLES[f] || f.replace(/\.md$/, "")).replace(/^[🏠📑🌐✅🚀📁📂🎯🔄🎭⭐⚡🔧🧠🔗🤖🏗️💰🔀📦👥📝❓📋] /, ""),
      markdown
    });
  }
  return docs;
}

function escapeHtml(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function convertLinks(text) {
  text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (match, linkText, url) => {
    if (url.endsWith('.md')) {
      const cleanUrl = url.replace(/\.md$/, "").toLowerCase().replace(/_/g, "-");
      return `<a href="#${cleanUrl}">${linkText}</a>`;
    }
    return `<a href="${url}" target="_blank">${linkText}</a>`;
  });
  return text;
}

function mdToHtml(md) {
  const lines = md.split("\n");
  const result = [];
  let i = 0;
  
  while (i < lines.length) {
    const line = lines[i];
    const trimmed = line.trim();
    
    if (trimmed.startsWith("```")) {
      const langMatch = trimmed.match(/^```(\w*)/);
      const lang = langMatch ? langMatch[1] : "";
      i++;
      const codeLines = [];
      while (i < lines.length && !lines[i].trim().startsWith("```")) {
        codeLines.push(lines[i]);
        i++;
      }
      i++;
      const code = codeLines.join("\n").trim();
      
      if (lang === "mermaid") {
        // Output mermaid block for rendering by Mermaid.js
        result.push(`<div class="mermaid">${code}</div>`);
      } else {
        const langClass = lang ? ` class="language-${lang}"` : "";
        result.push(`<pre><code${langClass}>${escapeHtml(code)}</code></pre>`);
      }
      continue;
    }
    
    if (trimmed.startsWith("# ")) {
      result.push(`<h1>${escapeHtml(trimmed.slice(2))}</h1>`);
      i++;
      continue;
    }
    if (trimmed.startsWith("## ")) {
      result.push(`<h2>${escapeHtml(trimmed.slice(3))}</h2>`);
      i++;
      continue;
    }
    if (trimmed.startsWith("### ")) {
      result.push(`<h3>${escapeHtml(trimmed.slice(4))}</h3>`);
      i++;
      continue;
    }
    if (trimmed.startsWith("#### ")) {
      result.push(`<h4>${escapeHtml(trimmed.slice(5))}</h4>`);
      i++;
      continue;
    }
    
    if (trimmed === "---" || trimmed === "***") {
      result.push("<hr>");
      i++;
      continue;
    }
    
    if (trimmed.startsWith("|")) {
      const tableRows = [];
      while (i < lines.length && lines[i].trim().startsWith("|")) {
        const row = lines[i].trim();
        if (row.replace(/[|:\-\s]/g, "").length === 0) {
          i++;
          continue;
        }
        const cells = row.split("|").map(c => c.trim()).filter(c => c.length > 0);
        tableRows.push(cells);
        i++;
      }
      if (tableRows.length > 0) {
        let table = "<table>";
        tableRows.forEach((row, idx) => {
          const tag = idx === 0 ? "th" : "td";
          table += "<tr>";
          row.forEach(cell => {
            const processedCell = convertLinks(cell)
              .replace(/`([^`]+)`/g, "<code>$1</code>")
              .replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>")
              .replace(/\*(.*?)\*/g, "<em>$1</em>");
            table += `<${tag}>${processedCell}</${tag}>`;
          });
          table += "</tr>";
        });
        table += "</table>";
        result.push(table);
      }
      continue;
    }
    
    if (trimmed.startsWith("- ")) {
      const items = [];
      while (i < lines.length) {
        const l = lines[i].trim();
        if (l.startsWith("- ")) {
          let content = l.slice(2);
          content = convertLinks(content)
            .replace(/`([^`]+)`/g, "<code>$1</code>")
            .replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>")
            .replace(/\*(.*?)\*/g, "<em>$1</em>");
          items.push(`<li>${content}</li>`);
          i++;
        } else if (l === "" || l === "---") {
          break;
        } else {
          break;
        }
      }
      if (items.length > 0) {
        result.push(`<ul>${items.join("")}</ul>`);
      }
      continue;
    }
    
    if (/^\d+\.\s/.test(trimmed)) {
      const items = [];
      while (i < lines.length) {
        const l = lines[i].trim();
        if (/^\d+\.\s/.test(l)) {
          let content = l.replace(/^\d+\.\s/, "");
          content = convertLinks(content)
            .replace(/`([^`]+)`/g, "<code>$1</code>")
            .replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>")
            .replace(/\*(.*?)\*/g, "<em>$1</em>");
          items.push(`<li>${content}</li>`);
          i++;
        } else if (l === "" || l === "---") {
          break;
        } else {
          break;
        }
      }
      if (items.length > 0) {
        result.push(`<ul>${items.join("")}</ul>`);
      }
      continue;
    }
    
    if (trimmed === "") {
      i++;
      continue;
    }
    
    const paraLines = [];
    while (i < lines.length && lines[i].trim() !== "" && !lines[i].trim().startsWith("---") && !lines[i].trim().startsWith("```") && !lines[i].trim().startsWith("#") && !lines[i].trim().startsWith("|") && !lines[i].trim().startsWith("- ") && !/^\d+\.\s/.test(lines[i].trim())) {
      paraLines.push(lines[i]);
      i++;
    }
    if (paraLines.length > 0) {
      let content = paraLines.join(" ");
      content = convertLinks(content)
        .replace(/`([^`]+)`/g, "<code>$1</code>")
        .replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>")
        .replace(/\*(.*?)\*/g, "<em>$1</em>");
      result.push(`<p>${content}</p>`);
    }
  }
  
  return result.join("\n\n");
}

function buildHtml(docs) {
  const tocItems = docs.map((d) => 
    `<li><a href="#${d.slug}">${escapeHtml(d.simpleTitle)}</a></li>`
  ).join("\n");
  
  const sections = docs.map((d) => {
    const content = mdToHtml(d.markdown);
    return `
<section id="${d.slug}" class="doc-section">
  <h2 class="section-title">${escapeHtml(d.title)}</h2>
  <div class="section-content">
    ${content}
  </div>
</section>`;
  }).join("\n");

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="description" content="AI-SDLC Platform — User Manual (v2.1.4)" />
  <title>AI-SDLC User Manual</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet" />
  <style>
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

* { box-sizing: border-box; }
html { scroll-behavior: smooth; }

body {
  margin: 0;
  min-height: 100vh;
  font-family: var(--font);
  font-size: 16px;
  line-height: 1.65;
  color: var(--text-primary);
  overflow-wrap: anywhere;
  background: var(--bg-base);
  background-image:
    radial-gradient(ellipse 120% 80% at 50% -20%, rgba(10, 132, 255, 0.06), transparent 50%),
    radial-gradient(ellipse 80% 50% at 100% 100%, rgba(88, 86, 214, 0.04), transparent 45%);
  -webkit-font-smoothing: antialiased;
}

a { color: var(--accent); text-decoration: none; }
a:hover { color: #409cff; }

/* Top Bar */
.top-bar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: calc(var(--header-h) + 8px);
  display: flex;
  align-items: center;
  gap: calc(var(--space) * 2);
  padding: 0 calc(var(--space) * 3);
  background: linear-gradient(180deg, rgba(12,12,14,0.95) 0%, rgba(12,12,14,0.85) 100%);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid rgba(255,255,255,0.06);
  z-index: 1000;
}

.brand {
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: 600;
  font-size: 15px;
  color: var(--text-primary);
}

.brand-logo {
  width: 28px;
  height: 28px;
  border-radius: 7px;
  background: linear-gradient(135deg, #0a84ff 0%, #5856d6 100%);
  display: grid;
  place-items: center;
  font-size: 14px;
  font-weight: 700;
  color: white;
}

.top-bar nav {
  display: flex;
  gap: 8px;
  margin-left: auto;
}

.top-bar nav a {
  padding: 8px 14px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 500;
  color: var(--text-secondary);
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.08);
  transition: all 0.2s var(--ease);
}

.top-bar nav a:hover {
  background: rgba(255, 255, 255, 0.09);
  color: var(--text-primary);
}

/* Layout */
.app {
  display: grid;
  grid-template-columns: 260px 1fr;
  min-height: 100vh;
  gap: calc(var(--space) * 3);
  padding: calc(var(--space) * 3);
  padding-top: calc(var(--space) * 13);
  max-width: 1400px;
  margin: 0 auto;
}

@media (max-width: 1024px) {
  .app { grid-template-columns: 1fr; }
  .sidebar { display: none; }
}

/* Sidebar */
.sidebar {
  position: sticky;
  top: calc(var(--space) * 13);
  align-self: start;
  max-height: calc(100vh - calc(var(--space) * 16));
  overflow-y: auto;
}

.sidebar-panel {
  padding: calc(var(--space) * 2.5);
  border-radius: var(--radius-lg);
  background: var(--bg-glass);
  border: 1px solid rgba(255,255,255,0.06);
  box-shadow: var(--shadow-md), var(--shadow-diffuse);
  backdrop-filter: blur(14px);
}

.sidebar-title {
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-secondary);
  margin-bottom: 16px;
}

.sidebar ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.sidebar li { margin: 4px 0; }

.sidebar a {
  display: block;
  padding: 8px 12px;
  border-radius: var(--radius-sm);
  font-size: 13px;
  color: var(--text-secondary);
  transition: all 0.2s var(--ease);
}

.sidebar a:hover {
  color: var(--text-primary);
  background: rgba(255,255,255,0.04);
}

/* Content */
.reading-column {
  flex: 1;
  width: 100%;
  max-width: var(--reading-width);
  margin: 0 auto;
}

.doc-section {
  margin-bottom: calc(var(--space) * 4);
  padding-bottom: calc(var(--space) * 4);
  border-bottom: 1px solid rgba(255,255,255,0.08);
}

.doc-section:last-child {
  border-bottom: none;
}

.section-title {
  font-size: 28px;
  font-weight: 600;
  letter-spacing: -0.02em;
  margin: 0 0 calc(var(--space) * 3);
  padding-bottom: calc(var(--space) * 1.5);
  border-bottom: 1px solid rgba(255,255,255,0.1);
}

.section-content h1 { font-size: 26px; margin: 0 0 16px; font-weight: 600; letter-spacing: -0.02em; }
.section-content h2 { font-size: 20px; margin: 24px 0 12px; font-weight: 600; padding-bottom: 8px; border-bottom: 1px solid rgba(255,255,255,0.1); }
.section-content h3 { font-size: 17px; margin: 20px 0 10px; font-weight: 600; }
.section-content h4 { font-size: 15px; margin: 16px 0 8px; font-weight: 600; }
.section-content p { margin: 0 0 14px; line-height: 1.65; }
.section-content strong { color: rgba(255,255,255,0.88); font-weight: 600; }
.section-content code {
  font-family: "SF Mono", ui-monospace, "Cascadia Code", monospace;
  font-size: 0.88em;
  padding: 3px 7px;
  border-radius: 6px;
  background: rgba(0,0,0,0.35);
  color: rgba(255,255,255,0.78);
}
.section-content pre {
  background: var(--bg-code);
  padding: 18px;
  border-radius: var(--radius-md);
  overflow-x: auto;
  margin: 20px 0;
  border: 1px solid rgba(255,255,255,0.07);
}
.section-content pre code { background: none; padding: 0; font-size: 13px; line-height: 1.55; color: rgba(255,255,255,0.75); }
.section-content table { width: 100%; border-collapse: collapse; margin: 20px 0; font-size: 14px; }
.section-content th, .section-content td { padding: 12px 16px; text-align: left; border-bottom: 1px solid rgba(255,255,255,0.08); }
.section-content th { font-weight: 600; color: var(--text-primary); background: rgba(0,0,0,0.2); }
.section-content tr:hover { background: rgba(255,255,255,0.02); }
.section-content ul, .section-content ol { margin: 12px 0; padding-left: 24px; }
.section-content li { margin: 6px 0; }
.section-content hr { border: none; border-top: 1px solid rgba(255,255,255,0.1); margin: 24px 0; }
.section-content a { color: var(--accent); }
.section-content a:hover { text-decoration: underline; }

/* Mermaid diagrams */
.mermaid {
  background: var(--bg-code);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: var(--radius-md);
  padding: 20px;
  margin: 20px 0;
  overflow-x: auto;
}

/* Syntax highlighting colors */
.language-bash { color: #79c0ff; }
.language-json { color: #a5d6ff; }
.language-yaml { color: #7ee787; }
.language-javascript { color: #f1e05a; }
.language-python { color: #79c0ff; }
.language-java { color: #b07219; }
.language-sh { color: #79c0ff; }
.language-zsh { color: #79c0ff; }

/* Token types for richer highlighting */
code .comment, .token.comment { color: #8b949e; font-style: italic; }
code .string, .token.string { color: #a5d6ff; }
code .keyword, .token.keyword { color: #ff7b72; }
code .function, .token.function { color: #d2a8ff; }
code .number, .token.number { color: #79c0ff; }
code .operator, .token.operator { color: #ff7b72; }
code .punctuation, .token.punctuation { color: #c9d1d9; }
code .tag, .token.tag { color: #7ee787; }
code .attr-name, .token.attr-name { color: #79c0ff; }
code .attr-value, .token.attr-value { color: #a5d6ff; }
code .boolean, .token.boolean { color: #ff7b72; }
code .property, .token.property { color: #79c0ff; }
  </style>
</head>
<body>
  <div class="top-bar">
    <div class="brand">
      <div class="brand-logo">AI</div>
      <span>AI-SDLC Platform</span>
    </div>
    <nav>
      <a href="#getting-started">Start</a>
      <a href="#happy-path-end-to-end">Happy Path</a>
      <a href="#commands">Commands</a>
      <a href="#faq">FAQ</a>
    </nav>
  </div>

  <div class="app">
    <aside class="sidebar">
      <div class="sidebar-panel">
        <div class="sidebar-title">Contents</div>
        <ul>
          ${tocItems}
        </ul>
      </div>
    </aside>

    <main class="reading-column">
      ${sections}
    </main>
  </div>
<script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<script>
  if (typeof mermaid !== 'undefined') {
    mermaid.initialize({ 
      startOnLoad: true, 
      theme: 'dark',
      themeVariables: {
        primaryColor: '#1c1c20',
        primaryTextColor: '#f0f6fc',
        primaryBorderColor: '#0a84ff',
        lineColor: '#0a84ff',
        secondaryColor: '#21262d',
        tertiaryColor: '#0a0a0c'
      }
    });
  }
</script>
</body>
</html>`;
}

const docs = loadDocs();
const html = buildHtml(docs);
fs.writeFileSync(OUT, html, "utf8");
console.log(`Generated manual.html (${docs.length} docs, ${(fs.statSync(OUT).size / 1024).toFixed(1)} KB)`);
