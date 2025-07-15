import * as fs from 'node:fs/promises';

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
  const matches = [...source.matchAll(/^([ \t]*)<(?:pre|xmp) class=['"]cddl['"] data-cddl-module=['"]((?:[a-zA-Z0-9_,-]+)+)['"]>([\s\S]*?)<\/(?:pre|xmp)>/gm)];

  const [local, remote] = matches.reduce(([local, remote], match) => {
    const [_, indentation, cddlModules, content] = match;

    let isLocal = cddlModules.indexOf('local-cddl') > -1;
    let isRemote = cddlModules.indexOf('remote-cddl') > -1;

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
