#!/usr/bin/env node

/**
 * CLAUDE.md line count and section statistics
 * Usage: node line-count.mjs <path-to-claude-md>
 * Output: JSON with total lines, sections, code blocks, tables
 * Exit codes: 0 = success, 1 = error
 */

import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

const filePath = process.argv[2];

if (!filePath) {
  console.error(JSON.stringify({ error: 'No file path provided', usage: 'node line-count.mjs <path-to-file>' }));
  process.exit(1);
}

const resolvedPath = resolve(filePath);

if (!existsSync(resolvedPath)) {
  console.error(JSON.stringify({ error: `File not found: ${resolvedPath}` }));
  process.exit(1);
}

let content;
try {
  content = readFileSync(resolvedPath, 'utf8');
} catch (err) {
  console.error(JSON.stringify({ error: `Cannot read file: ${err.message}` }));
  process.exit(1);
}

const lines = content.split('\n');
const totalLines = lines.length;
const nonEmptyLines = lines.filter(l => l.trim().length > 0).length;

const sections = [];
let currentSection = null;
let inCodeBlock = false;
let codeBlockLines = 0;
let tableLines = 0;

for (let i = 0; i < lines.length; i++) {
  const line = lines[i];

  // Track code blocks
  if (line.trimStart().startsWith('```')) {
    inCodeBlock = !inCodeBlock;
    codeBlockLines++;
    if (currentSection) currentSection.codeBlockLines++;
    continue;
  }

  if (inCodeBlock) {
    codeBlockLines++;
    if (currentSection) currentSection.codeBlockLines++;
    continue;
  }

  // Track tables
  if (/^\s*\|.*\|/.test(line)) {
    tableLines++;
    if (currentSection) currentSection.tableLines++;
    continue;
  }

  // Detect headings (## or ###)
  const headingMatch = line.match(/^(#{1,6})\s+(.+)$/);
  if (headingMatch) {
    const level = headingMatch[1].length;
    if (level >= 2) {
      if (currentSection) {
        currentSection.endLine = i;
        currentSection.lines = currentSection.endLine - currentSection.startLine;
        sections.push(currentSection);
      }
      currentSection = {
        heading: headingMatch[2].trim(),
        level,
        startLine: i + 1,
        endLine: null,
        lines: 0,
        codeBlockLines: 0,
        tableLines: 0
      };
    }
  }
}

// Close last section
if (currentSection) {
  currentSection.endLine = totalLines;
  currentSection.lines = currentSection.endLine - currentSection.startLine;
  sections.push(currentSection);
}

const result = {
  file: resolvedPath,
  totalLines,
  nonEmptyLines,
  codeBlockLines,
  tableLines,
  sectionCount: sections.length,
  sections
};

console.log(JSON.stringify(result, null, 2));
