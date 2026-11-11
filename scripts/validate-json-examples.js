#!/usr/bin/env node

import {promisify} from 'node:util';
import {exec as _exec} from 'node:child_process';
import * as parse5 from 'parse5';

const exec = promisify(_exec);

/**
 * Determine whether a given node represents an element that bears a given
 * class name.
 */
const hasClass = (node, className) => {
  return node.attrs && node.attrs.some((attr) => {
    return attr.name === 'class' &&
      attr.value.split(/\s+/).includes(className);
  });
};

/**
 * Find all descendants of a given node that are elements bearing a given class
 * name.
 */
const getElementsByClassName = function * (node, className) {
  if (hasClass(node, className)) {
    yield node;
  } else if (node.childNodes) {
    for (const childNode of node.childNodes) {
      yield * getElementsByClassName(childNode, className);
    }
  }
};

/**
 * Compute the text content of a given subtree.
 */
const textContent = function (node) {
  if (node.nodeName === '#text') {
    return node.value;
  }
  if (!node.childNodes) {
    return '';
  }
  return node.childNodes.map(textContent).join('');
};

/**
 * Format a given string as a Markdown-style quotation by prefixing every line
 * with the character sequence `> `.
 */
const quote = (text) => text.split('\n').map((line) => `> ${line}`).join('\n');

const {stdout} = await exec('bikeshed --silent spec index.bs -');
const document = parse5.parse(stdout);

const errors = Array.from(getElementsByClassName(document, 'language-json'))
  .reduce((errors, node) => {
    const json = textContent(node);
    try {
      JSON.parse(json);
    } catch (error) {
      errors.push({ source: json, message: error.message });
    }
    return errors;
  }, []);

console.log(`${errors.length} JSON error(s) found.\n`);

for (const error of errors) {
  console.log(`Source:\n${quote(error.source.trim())}`);
  console.log(`Message: ${error.message}\n`);
}

process.exitCode = errors.length > 0 ? 1 : 0;
