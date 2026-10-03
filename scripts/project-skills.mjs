import { readFile, readdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const SKILL_NAME_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

function fail(message) {
  throw new Error(message);
}

function parseScalar(rawValue, key, filePath) {
  const value = rawValue.trim();
  if (!value) {
    fail(`${filePath}: frontmatter '${key}' must not be empty`);
  }

  if (value.startsWith("'")) {
    if (!value.endsWith("'")) {
      fail(`${filePath}: unterminated single-quoted '${key}' value`);
    }
    return value.slice(1, -1).replaceAll("''", "'");
  }

  if (value.startsWith('"')) {
    try {
      return JSON.parse(value);
    } catch {
      fail(`${filePath}: invalid double-quoted '${key}' value`);
    }
  }

  return value;
}

export function parseSkillFrontmatter(content, filePath = 'SKILL.md') {
  const lines = content.replaceAll('\r\n', '\n').split('\n');
  if (lines[0]?.trim() !== '---') {
    fail(`${filePath}: missing opening frontmatter delimiter`);
  }

  const end = lines.findIndex((line, index) => index > 0 && line.trim() === '---');
  if (end < 0) {
    fail(`${filePath}: missing closing frontmatter delimiter`);
  }

  const fields = new Map();
  for (let index = 1; index < end; index += 1) {
    const line = lines[index];
    if (!line || /^\s/.test(line)) {
      continue;
    }

    const match = /^([A-Za-z][A-Za-z0-9_-]*):\s*(.*)$/.exec(line);
    if (!match) {
      continue;
    }

    const [, key, rawValue] = match;
    if (rawValue === '|' || rawValue === '>') {
      const block = [];
      while (index + 1 < end && /^\s/.test(lines[index + 1])) {
        index += 1;
        block.push(lines[index].trim());
      }
      fields.set(key, block.join(rawValue === '>' ? ' ' : '\n').trim());
    } else {
      fields.set(key, parseScalar(rawValue, key, filePath));
    }
  }

  const name = fields.get('name');
  const description = fields.get('description');
  if (!name) {
    fail(`${filePath}: required frontmatter field 'name' is missing`);
  }
  if (!description) {
    fail(`${filePath}: required frontmatter field 'description' is missing`);
  }
  if (!SKILL_NAME_PATTERN.test(name)) {
    fail(`${filePath}: frontmatter name '${name}' is not a lowercase hyphenated skill name`);
  }

  return { name, description };
}

function toPortablePath(value) {
  return value.replaceAll('\\', '/');
}

export async function inventoryLocalSkills(root) {
  const skillsRoot = path.join(root, 'skills');
  let entries;
  try {
    entries = await readdir(skillsRoot, { withFileTypes: true });
  } catch (error) {
    if (error.code === 'ENOENT') {
      return [];
    }
    throw error;
  }

  const inventory = [];
  for (const entry of entries.sort((left, right) => left.name.localeCompare(right.name))) {
    if (!entry.isDirectory() || entry.name.startsWith('.')) {
      continue;
    }

    const relativeSkillPath = `skills/${entry.name}/SKILL.md`;
    const skillPath = path.join(root, ...relativeSkillPath.split('/'));
    let content;
    try {
      content = await readFile(skillPath, 'utf8');
    } catch (error) {
      if (error.code === 'ENOENT') {
        continue;
      }
      throw error;
    }

    const frontmatter = parseSkillFrontmatter(content, relativeSkillPath);
    if (frontmatter.name !== entry.name) {
      fail(
        `${relativeSkillPath}: directory '${entry.name}' does not match frontmatter name '${frontmatter.name}'`,
      );
    }

    inventory.push({
      name: entry.name,
      skillPath: relativeSkillPath,
    });
  }

  return inventory;
}

function isRecord(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

export function parseSkillsLock(content, filePath = 'skills-lock.json') {
  let lock;
  try {
    lock = JSON.parse(content);
  } catch (error) {
    fail(`${filePath}: invalid JSON (${error.message})`);
  }
  if (!isRecord(lock) || !isRecord(lock.skills)) {
    fail(`${filePath}: expected a top-level 'skills' object`);
  }
  return lock;
}

export function isAbsoluteLocalSource(source) {
  return (
    typeof source === 'string' &&
    (path.isAbsolute(source) || path.win32.isAbsolute(source) || path.posix.isAbsolute(source))
  );
}

export function normalizeLocalSkillEntries(lockInput, inventory) {
  const lock = structuredClone(lockInput);
  const localByName = new Map(inventory.map((skill) => [skill.name, skill]));
  let changed = false;

  for (const skill of inventory) {
    const entry = lock.skills[skill.name];
    if (!isRecord(entry)) {
      fail(`skills-lock.json: tracked local skill '${skill.name}' has no lock entry`);
    }

    if (entry.sourceType === 'local' && entry.skillPath === undefined) {
      entry.skillPath = skill.skillPath;
      changed = true;
    }

    const lockedPath =
      typeof entry.skillPath === 'string' ? toPortablePath(entry.skillPath) : entry.skillPath;
    if (lockedPath !== skill.skillPath) {
      fail(
        `skills-lock.json: local skill '${skill.name}' expected path '${skill.skillPath}', found '${entry.skillPath ?? 'missing'}'`,
      );
    }

    if (entry.sourceType === 'local' && isAbsoluteLocalSource(entry.source)) {
      entry.source = '.';
      changed = true;
    }

    if (entry.sourceType === 'local' && entry.source !== '.') {
      fail(
        `skills-lock.json: local skill '${skill.name}' must use portable source '.', found '${entry.source ?? 'missing'}'`,
      );
    }
  }

  for (const [name, entry] of Object.entries(lock.skills)) {
    if (!isRecord(entry)) {
      fail(`skills-lock.json: skill '${name}' must be an object`);
    }
    if ((entry.sourceType === 'local' || entry.source === '.') && !localByName.has(name)) {
      fail(`skills-lock.json: local entry '${name}' has no matching tracked skill source`);
    }
  }

  for (const [name, entry] of Object.entries(lock.skills)) {
    if (isAbsoluteLocalSource(entry.source)) {
      fail(
        `skills-lock.json: absolute local source remains for '${name}': '${entry.source}'`,
      );
    }
  }

  return { lock, changed };
}

export function expectedInstalledSkillNames(lock, inventory) {
  return [...new Set([...Object.keys(lock.skills), ...inventory.map((skill) => skill.name)])].sort(
    (left, right) => left.localeCompare(right),
  );
}

export async function normalizeLocalSkillsLock(root, { write = true } = {}) {
  const lockPath = path.join(root, 'skills-lock.json');
  const original = await readFile(lockPath, 'utf8');
  const inventory = await inventoryLocalSkills(root);
  const parsed = parseSkillsLock(original, 'skills-lock.json');
  const result = normalizeLocalSkillEntries(parsed, inventory);

  if (write && result.changed) {
    await writeFile(lockPath, `${JSON.stringify(result.lock, null, 2)}\n`, 'utf8');
  }

  return {
    ...result,
    inventory,
    expected: expectedInstalledSkillNames(result.lock, inventory),
  };
}

function writeNames(names) {
  if (names.length > 0) {
    process.stdout.write(`${names.join('\n')}\n`);
  }
}

async function main() {
  const command = process.argv[2];
  const root = path.resolve(process.argv[3] ?? process.cwd());

  if (command === 'local') {
    writeNames((await inventoryLocalSkills(root)).map((skill) => skill.name));
    return;
  }
  if (command === 'normalize') {
    await normalizeLocalSkillsLock(root);
    return;
  }
  if (command === 'expected') {
    const result = await normalizeLocalSkillsLock(root, { write: false });
    writeNames(result.expected);
    return;
  }

  fail('usage: node scripts/project-skills.mjs <local|normalize|expected> [repository-root]');
}

const currentFile = path.resolve(fileURLToPath(import.meta.url));
const invokedFile = process.argv[1] ? path.resolve(process.argv[1]) : '';
if (currentFile.toLowerCase() === invokedFile.toLowerCase()) {
  main().catch((error) => {
    console.error(`project-skills: ${error.message}`);
    process.exitCode = 1;
  });
}
