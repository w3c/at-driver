#!/usr/bin/env node

import {readFileSync} from 'fs';
import Ajv from 'ajv/dist/2020.js';

function validateJsonSchema(filename) {
  const ajv = new Ajv({strict: true});
  try {
    const text = readFileSync(filename, 'utf-8');
    const schema = JSON.parse(text);
    ajv.compile(schema);
  } catch (error) {
    console.error(`Error validating "${filename}": ${error}`);
    process.exitCode = 1;
    return;
  }
  console.log(`JSON Schema in "${filename}" is valid.`);
}

validateJsonSchema('./schemas/at-driver-local.json');
validateJsonSchema('./schemas/at-driver-remote.json');
