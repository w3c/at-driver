import { Lexer, Parser } from 'cddl';
import * as fs from 'node:fs/promises';

function assert(condition, message) {
  if (!condition) {
    throw new Error(`Assertion failed: ${message}`);
  }
}

function cddlParse(input) {
  const l = new Lexer(input);
  const parser = new Parser(l);
  return parser.parse();
}

function cddlToJSONSchema(input) {
  const cddlAst = cddlParse(input);
  const jsonSchemaAst = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "TODO",
    "$defs": {},
  };
  for (const obj of cddlAst) {
    console.log(JSON.stringify(obj, null, 2)); // TODO
    // For Command, need to copy over 'id' to all schemas in CommandData,
    // since JSON Schema can't add to schemas together, and we don't
    // want to allow any additional properties.
  }
}

// Extract CDDL from index.bs and write to files

const source = await fs.readFile('index.bs', { encoding: 'utf8' });
const localCddlArr = [];
const remoteCddlArr = [];
let matches = [...source.matchAll(/^([ \t]*)<pre class=['"]cddl((?: [a-zA-Z0-9_-]+)+)['"]>([\s\S]*?)<\/pre>/gm)];
for (const match of matches) {
  let indentation = match[1];
  let isRemote = match[2].indexOf(' remote') > -1;
  let isLocal = match[2].indexOf(' local') > -1;
  if (!isRemote && !isLocal) {
    continue;
  }
  let cddlBlock = match[3].trim();
  if (indentation.length > 0) {
    let indentationRegexp = new RegExp(`^${match[1]}`);
    let lines = cddlBlock.split('\n');
    const result = [];
    for (const line of lines) {
      result.push(line.replace(indentationRegexp, ''));
    }
    cddlBlock = result.join('\n');
  }
  if (isLocal) {
    localCddlArr.push(cddlBlock);
  }
  if (isRemote) {
    remoteCddlArr.push(cddlBlock);
  }
}

const localCddl = localCddlArr.join('\n\n') + '\n';
const remoteCddl = remoteCddlArr.join('\n\n') + '\n';
try {
  await fs.mkdir('schemas');
} catch(ex) {
  if (ex.code !== 'EEXIST') {
    throw ex;
  }
}
await fs.writeFile('schemas/at-driver-local.cddl', localCddl);
await fs.writeFile('schemas/at-driver-remote.cddl', remoteCddl);

// Convert CDDL to JSON Schema
cddlToJSONSchema(localCddl);
cddlToJSONSchema(remoteCddl);
