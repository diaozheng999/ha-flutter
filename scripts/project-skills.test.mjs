import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

import {
  expectedInstalledSkillNames,
  inventoryLocalSkills,
  normalizeLocalSkillsLock,
} from './project-skills.mjs';

async function fixture(t) {
  const root = await mkdtemp(path.join(os.tmpdir(), 'ha-flutter-project-skills-'));
  t.after(() => rm(root, { force: true, recursive: true }));
  return root;
}

async function addSkill(root, directoryName, frontmatterName = directoryName) {
  const skillRoot = path.join(root, 'skills', directoryName);
  await mkdir(skillRoot, { recursive: true });
  await writeFile(
    path.join(skillRoot, 'SKILL.md'),
    `---\nname: ${frontmatterName}\ndescription: Test skill ${frontmatterName}\n---\n`,
    'utf8',
  );
}

async function writeLock(root, skills, content) {
  const lockContent = content ?? `${JSON.stringify({ version: 1, skills }, null, 2)}\n`;
  await writeFile(path.join(root, 'skills-lock.json'), lockContent, 'utf8');
}

test('normalizes local sources and preserves hashes, external entries, union, and idempotence', async (t) => {
  const root = await fixture(t);
  await addSkill(root, 'alpha-skill');
  const external = {
    source: 'example/external-skills',
    sourceType: 'github',
    skillPath: 'skills/external-skill/SKILL.md',
    computedHash: 'external-hash',
  };
  await writeLock(root, {
    'alpha-skill': {
      source: root,
      sourceType: 'local',
      computedHash: 'local-hash',
    },
    'external-skill': external,
  });

  const first = await normalizeLocalSkillsLock(root);
  assert.equal(first.changed, true);
  assert.equal(first.lock.skills['alpha-skill'].source, '.');
  assert.equal(first.lock.skills['alpha-skill'].skillPath, 'skills/alpha-skill/SKILL.md');
  assert.equal(first.lock.skills['alpha-skill'].computedHash, 'local-hash');
  assert.deepEqual(first.lock.skills['external-skill'], external);
  assert.deepEqual(first.expected, ['alpha-skill', 'external-skill']);

  const once = await readFile(path.join(root, 'skills-lock.json'), 'utf8');
  const second = await normalizeLocalSkillsLock(root);
  const twice = await readFile(path.join(root, 'skills-lock.json'), 'utf8');
  assert.equal(second.changed, false);
  assert.equal(twice, once);
});

test('rejects a directory and frontmatter name mismatch', async (t) => {
  const root = await fixture(t);
  await addSkill(root, 'directory-name', 'declared-name');
  await assert.rejects(
    inventoryLocalSkills(root),
    /directory 'directory-name' does not match frontmatter name 'declared-name'/,
  );
});

test('rejects a local lock path mismatch', async (t) => {
  const root = await fixture(t);
  await addSkill(root, 'alpha-skill');
  await writeLock(root, {
    'alpha-skill': {
      source: '.',
      sourceType: 'local',
      skillPath: 'skill/alpha-skill/SKILL.md',
      computedHash: 'hash',
    },
  });
  await assert.rejects(normalizeLocalSkillsLock(root), /expected path/);
});

test('rejects an unmatched local lock entry', async (t) => {
  const root = await fixture(t);
  await addSkill(root, 'alpha-skill');
  await writeLock(root, {
    'alpha-skill': {
      source: '.',
      sourceType: 'local',
      skillPath: 'skills/alpha-skill/SKILL.md',
      computedHash: 'hash',
    },
    ghost: {
      source: '.',
      sourceType: 'local',
      skillPath: 'skills/ghost/SKILL.md',
      computedHash: 'ghost-hash',
    },
  });
  await assert.rejects(normalizeLocalSkillsLock(root), /local entry 'ghost' has no matching/);
});

test('rejects an absolute source that remains after local normalization', async (t) => {
  const root = await fixture(t);
  await addSkill(root, 'alpha-skill');
  await writeLock(root, {
    'alpha-skill': {
      source: 'C:\\stale-checkout',
      sourceType: 'github',
      skillPath: 'skills/alpha-skill/SKILL.md',
      computedHash: 'hash',
    },
  });
  await assert.rejects(normalizeLocalSkillsLock(root), /absolute local source remains/);
});

test('computes the expected installed union independently', () => {
  const names = expectedInstalledSkillNames(
    { skills: { external: {}, shared: {} } },
    [
      { name: 'local', skillPath: 'skills/local/SKILL.md' },
      { name: 'shared', skillPath: 'skills/shared/SKILL.md' },
    ],
  );
  assert.deepEqual(names, ['external', 'local', 'shared']);
});

test('leaves an already-normalized lock byte-identical', async (t) => {
  const root = await fixture(t);
  await addSkill(root, 'alpha-skill');
  const original = [
    '{',
    '  "version": 1,',
    '  "skills": {',
    '    "alpha-skill": {',
    '      "source": ".",',
    '      "sourceType": "local",',
    '      "skillPath": "skills/alpha-skill/SKILL.md",',
    '      "computedHash": "hash"',
    '    }',
    '  }',
    '}',
    '',
  ].join('\r\n');
  await writeLock(root, {}, original);

  const result = await normalizeLocalSkillsLock(root);
  assert.equal(result.changed, false);
  assert.equal(await readFile(path.join(root, 'skills-lock.json'), 'utf8'), original);
});
