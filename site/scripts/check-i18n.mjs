import { readdirSync, readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const i18nDir = join(__dirname, '..', 'src', 'i18n');

function collectKeys(obj, prefix = '') {
  const keys = [];
  if (Array.isArray(obj)) {
    obj.forEach((item, index) => {
      keys.push(...collectKeys(item, `${prefix}[${index}]`));
    });
    return keys;
  }
  if (obj !== null && typeof obj === 'object') {
    for (const [k, v] of Object.entries(obj)) {
      const nextPrefix = prefix ? `${prefix}.${k}` : k;
      keys.push(...collectKeys(v, nextPrefix));
    }
    return keys;
  }
  keys.push({ key: prefix, value: obj });
  return keys;
}

const files = readdirSync(i18nDir).filter((f) => f.endsWith('.json')).sort();
if (!files.includes('en.json')) {
  console.error('Missing template locale: en.json');
  process.exit(1);
}

const templateData = JSON.parse(readFileSync(join(i18nDir, 'en.json'), 'utf8'));
const templateEntries = collectKeys(templateData);
const templateKeys = new Set(templateEntries.map((e) => e.key));

let hasErrors = false;

for (const file of files) {
  const data = JSON.parse(readFileSync(join(i18nDir, file), 'utf8'));
  const entries = collectKeys(data);
  const keys = new Set(entries.map((e) => e.key));

  for (const key of templateKeys) {
    if (!keys.has(key)) {
      console.error(`[${file}] Missing key: ${key}`);
      hasErrors = true;
    }
  }
  for (const key of keys) {
    if (!templateKeys.has(key)) {
      console.error(`[${file}] Extra key not in en.json: ${key}`);
      hasErrors = true;
    }
  }
  for (const { key, value } of entries) {
    if (typeof value !== 'string' || value.trim().length === 0) {
      console.error(`[${file}] Empty or non-string value for key: ${key}`);
      hasErrors = true;
    }
  }
}

if (hasErrors) {
  process.exit(1);
}

console.log(`i18n check passed for ${files.length} locale(s): ${files.join(', ')} (${templateKeys.size} keys each).`);
