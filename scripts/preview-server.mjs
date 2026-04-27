#!/usr/bin/env node

/**
 * Documentation Preview Server
 *
 * Simple HTTP server for local development and testing
 * Serves the generated manual.html with live-reload capability
 */

import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const htmlFile = path.join(__dirname, '..', 'manual.html');
const PORT = process.env.PORT || 8080;
const HOST = '127.0.0.1';

/**
 * Mime types
 */
const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
};

/**
 * Get mime type for file
 */
function getMimeType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  return mimeTypes[ext] || 'text/plain';
}

/**
 * Create HTTP server
 */
const server = http.createServer((req, res) => {
  const url = req.url === '/' ? '/manual.html' : req.url;
  const filePath = url === '/manual.html' ? htmlFile : path.join(__dirname, '..', url);

  // Security: prevent directory traversal
  const normalized = path.normalize(filePath);
  const baseDir = path.dirname(htmlFile);
  if (!normalized.startsWith(baseDir)) {
    res.writeHead(403, { 'Content-Type': 'text/plain' });
    res.end('Forbidden');
    return;
  }

  // Serve manual.html
  if (url === '/manual.html' || url === '/') {
    if (fs.existsSync(htmlFile)) {
      const content = fs.readFileSync(htmlFile, 'utf8');
      res.writeHead(200, {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'no-cache, must-revalidate',
      });
      res.end(content);
    } else {
      res.writeHead(404, { 'Content-Type': 'text/html' });
      res.end(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Documentation Not Found</title>
          <style>
            body { font-family: system-ui; padding: 2rem; }
            h1 { color: #ef4444; }
          </style>
        </head>
        <body>
          <h1>Documentation Not Generated</h1>
          <p>The manual.html file was not found.</p>
          <p>Run <code>npm run build:docs</code> first to generate the documentation.</p>
          <p><a href="/">Retry</a></p>
        </body>
        </html>
      `);
    }
    return;
  }

  // Serve other files
  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const mimeType = getMimeType(filePath);
    const content = fs.readFileSync(filePath);
    res.writeHead(200, { 'Content-Type': mimeType });
    res.end(content);
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

/**
 * Start server
 */
server.listen(PORT, HOST, () => {
  console.log('📚 Documentation Preview Server');
  console.log('================================\n');
  console.log(`✓ Server running at http://${HOST}:${PORT}`);
  console.log(`✓ Opening http://${HOST}:${PORT}/manual.html\n`);
  console.log('Press Ctrl+C to stop\n');

  // Try to open in browser
  try {
    const { spawn } = await import('child_process');
    const openCmd = process.platform === 'darwin' ? 'open' : process.platform === 'win32' ? 'start' : 'xdg-open';
    spawn(openCmd, [`http://${HOST}:${PORT}`], { detached: true });
  } catch (e) {
    // Browser open failed, but server is still running
  }
});

/**
 * Graceful shutdown
 */
process.on('SIGINT', () => {
  console.log('\n\nShutting down server...');
  server.close(() => {
    console.log('✓ Server stopped');
    process.exit(0);
  });
});

server.on('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    console.error(`❌ Port ${PORT} is already in use`);
    console.error(`Try: PORT=8081 npm run preview:docs`);
  } else {
    console.error('❌ Server error:', error.message);
  }
  process.exit(1);
});
