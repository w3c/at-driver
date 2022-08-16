import { Lexer, Parser } from 'cddl/build/index.js';
import * as fs from 'node:fs/promises';

const parseCddl = input => new Parser(new Lexer(input)).parse();

const removeIndentation = (indentation, cddl) => {
  if (indentation.length === 0) {
    return cddl;
  }

  let indentationRegexp = new RegExp(`^${indentation}`);
  return cddl
      .split('\n')
      .map(line => line.replace(indentationRegexp, ''))
      .join('\n');
}

const formatCddl = cddl => cddl.join('\n\n').trim() + '\n';

const extractCddlFromSpec = async () => {
  const source = await fs.readFile('index.bs', { encoding: 'utf8' });
  const matches = [...source.matchAll(/^([ \t]*)<pre class=['"]cddl((?: [a-zA-Z0-9_-]+)+)['"]>([\s\S]*?)<\/pre>/gm)];

  const [local, remote] = matches.reduce(([local, remote], match) => {
    const [_, indentation, cssClass, content] = match;

    let isLocal = cssClass.indexOf(' local-cddl') > -1;
    let isRemote = cssClass.indexOf(' remote-cddl') > -1;

    if (!isLocal && !isRemote) {
      return [local, remote];
    }

    let cddl = removeIndentation(indentation, content.trim());

    if (isLocal) {
      local.push(cddl);
    }
    if (isRemote) {
      remote.push(cddl);
    }

    return [local, remote];
  }, [[], []])

  return [
      formatCddl(local),
      formatCddl(remote)
  ]
}

try {
  await fs.mkdir('schemas');
} catch(ex) {
  if (ex.code !== 'EEXIST') {
    throw ex;
  }
}

const [localCddl, remoteCddl] = await extractCddlFromSpec();

await fs.writeFile('schemas/at-driver-local.cddl', localCddl);
await fs.writeFile('schemas/at-driver-remote.cddl', remoteCddl);

// Check that the CDDL can be parsed
parseCddl(localCddl);
parseCddl(remoteCddl);
