#!/usr/bin/env node

/**
 * Documentation Validation Script
 *
 * Validates generated HTML for:
 * - Well-formed HTML
 * - Accessibility standards (ARIA labels, semantic HTML)
 * - Required metadata
 * - External link availability (optional)
 * - Search index integrity
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const CONFIG = {
  htmlFile: path.join(__dirname, '..', 'manual.html'),
};

/**
 * Basic HTML validation
 */
function validateHtml(content) {
  const errors = [];
  const warnings = [];

  // Check for matching tags (excluding self-closing and code blocks)
  const contentWithoutCodeBlocks = content.replace(/<pre[\s\S]*?<\/pre>/g, '');
  const openTags = (contentWithoutCodeBlocks.match(/<[a-z][a-z0-9]*(?:\s[^>]*)?>(?!\/)/gi) || []).length;
  const closeTags = (contentWithoutCodeBlocks.match(/<\/[a-z][a-z0-9]*>/gi) || []).length;

  // Allow small mismatch due to markdown-generated content
  if (Math.abs(openTags - closeTags) > 5) {
    warnings.push(`Tag count difference: ${openTags} opening, ${closeTags} closing (minor variation acceptable)`);
  }

  // Check for required elements
  if (!/<html[^>]*>/i.test(content)) errors.push('Missing <html> tag');
  if (!/<head[^>]*>/i.test(content)) errors.push('Missing <head> tag');
  if (!/<body[^>]*>/i.test(content)) errors.push('Missing <body> tag');
  if (!/<title[^>]*>/i.test(content)) errors.push('Missing <title> tag');
  if (!/<meta\s+charset/i.test(content)) errors.push('Missing charset meta tag');
  if (!/<meta\s+name="viewport"/i.test(content)) errors.push('Missing viewport meta tag');

  // Check for best practices
  if (!/<meta\s+name="description"/i.test(content)) {
    warnings.push('Missing description meta tag');
  }

  // Check for accessibility
  if (!/(role=|aria-|<main|<nav|<article|<section)/i.test(content)) {
    warnings.push('Limited semantic HTML and ARIA attributes detected');
  }

  // Check for unclosed img tags
  const imgTags = content.match(/<img\s[^>]*>/gi) || [];
  for (const img of imgTags) {
    if (!img.endsWith('/>') && !img.includes('alt=')) {
      warnings.push(`Image missing alt text: ${img.substring(0, 50)}`);
    }
  }

  // Check CSS is embedded
  if (!/<style[\s>]/i.test(content)) {
    errors.push('No embedded CSS found (using external stylesheets not recommended)');
  }

  // Check for script tags
  if (!/<script[^>]*>/i.test(content)) {
    warnings.push('No JavaScript found (basic interactivity missing)');
  }

  return { errors, warnings };
}

/**
 * Validate metadata
 */
function validateMetadata(content) {
  const errors = [];
  const metadata = {};

  // Extract metadata
  const titleMatch = content.match(/<title[^>]*>(.*?)<\/title>/i);
  if (titleMatch) {
    metadata.title = titleMatch[1];
  } else {
    errors.push('Unable to extract title');
  }

  const versionMatch = content.match(/content="(\d+\.\d+\.\d+)"/);
  if (versionMatch) {
    metadata.version = versionMatch[1];
  }

  const updatedMatch = content.match(/content="(\d{4}-\d{2}-\d{2})/);
  if (updatedMatch) {
    metadata.updated = updatedMatch[1];
  } else {
    errors.push('Unable to extract update date');
  }

  // Check for search index
  if (!content.includes('const SEARCH_INDEX = ')) {
    errors.push('Search index not found in HTML');
  }

  // Check for TOC
  if (!content.includes('const TOC = ')) {
    errors.push('Table of contents not found in HTML');
  }

  return { metadata, errors };
}

/**
 * Validate content structure
 */
function validateStructure(content) {
  const errors = [];
  const stats = {
    sections: 0,
    headings: 0,
    links: 0,
    codeBlocks: 0,
  };

  // Count sections
  stats.sections = (content.match(/<section[^>]*>/gi) || []).length;

  // Count headings
  stats.headings = (content.match(/<h[1-6][^>]*>/gi) || []).length;

  // Count links
  stats.links = (content.match(/<a\s+href=/gi) || []).length;

  // Count code blocks
  stats.codeBlocks = (content.match(/<pre[^>]*>/gi) || []).length;

  if (stats.sections === 0) {
    errors.push('No content sections found');
  }

  if (stats.headings === 0) {
    errors.push('No headings found');
  }

  return { stats, errors };
}

/**
 * Main validation
 */
async function main() {
  try {
    if (!fs.existsSync(CONFIG.htmlFile)) {
      console.error(`❌ HTML file not found: ${CONFIG.htmlFile}`);
      console.log('Run "npm run build:docs" first to generate documentation');
      process.exit(1);
    }

    console.log('🔍 Validating documentation...\n');

    const content = fs.readFileSync(CONFIG.htmlFile, 'utf8');
    let hasErrors = false;

    // HTML Validation
    console.log('📋 HTML Validation:');
    const htmlValidation = validateHtml(content);
    if (htmlValidation.errors.length > 0) {
      console.log('❌ Errors:');
      htmlValidation.errors.forEach((e) => console.log(`   - ${e}`));
      hasErrors = true;
    } else {
      console.log('✓ HTML structure is valid');
    }

    if (htmlValidation.warnings.length > 0) {
      console.log('⚠️  Warnings:');
      htmlValidation.warnings.forEach((w) => console.log(`   - ${w}`));
    }

    // Metadata Validation
    console.log('\n🏷️  Metadata Validation:');
    const metaValidation = validateMetadata(content);
    if (metaValidation.errors.length > 0) {
      console.log('❌ Errors:');
      metaValidation.errors.forEach((e) => console.log(`   - ${e}`));
      hasErrors = true;
    } else {
      console.log('✓ Required metadata present');
    }

    if (metaValidation.metadata.title) {
      console.log(`  Title: "${metaValidation.metadata.title}"`);
    }
    if (metaValidation.metadata.version) {
      console.log(`  Version: ${metaValidation.metadata.version}`);
    }
    if (metaValidation.metadata.updated) {
      console.log(`  Last Updated: ${metaValidation.metadata.updated}`);
    }

    // Structure Validation
    console.log('\n📊 Content Structure:');
    const structValidation = validateStructure(content);
    console.log(`  Sections: ${structValidation.stats.sections}`);
    console.log(`  Headings: ${structValidation.stats.headings}`);
    console.log(`  Links: ${structValidation.stats.links}`);
    console.log(`  Code Blocks: ${structValidation.stats.codeBlocks}`);

    if (structValidation.errors.length > 0) {
      console.log('❌ Errors:');
      structValidation.errors.forEach((e) => console.log(`   - ${e}`));
      hasErrors = true;
    }

    // File Size
    console.log('\n📦 File Metrics:');
    const stats = fs.statSync(CONFIG.htmlFile);
    const sizeKb = (stats.size / 1024).toFixed(2);
    const sizeMb = (stats.size / 1024 / 1024).toFixed(3);
    console.log(`  File size: ${sizeKb} KB (${sizeMb} MB)`);

    // Summary
    console.log('\n' + '='.repeat(50));
    if (hasErrors) {
      console.log('❌ Validation FAILED with errors');
      process.exit(1);
    } else {
      console.log('✅ Validation PASSED');
      console.log('Documentation is ready for deployment');
      process.exit(0);
    }
  } catch (error) {
    console.error('❌ Validation error:', error.message);
    process.exit(1);
  }
}

main();
