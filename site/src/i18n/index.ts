import en from './en.json';
import fr from './fr.json';

export type Translations = typeof en;

export interface LocaleConfig {
  code: string;
  label: string;
  nativeName: string;
  hreflang: string;
  translations: Translations;
}

/**
 * Supported site locales.
 * To add a new language:
 * 1. Create `src/i18n/<code>.json` matching `en.json` keys.
 * 2. Import it and add an entry here.
 * 3. Add the locale code to `i18n.locales` in `astro.config.mjs`.
 */
export const LOCALES: readonly LocaleConfig[] = [
  {
    code: 'en',
    label: 'EN',
    nativeName: 'English',
    hreflang: 'en',
    translations: en,
  },
  {
    code: 'fr',
    label: 'FR',
    nativeName: 'Français',
    hreflang: 'fr',
    translations: fr,
  },
];

export const DEFAULT_LOCALE = 'en';

export function getLocaleConfig(locale: string): LocaleConfig {
  return LOCALES.find((entry) => entry.code === locale) ?? LOCALES[0];
}

export function getLocalePath(locale: string, base: string): string {
  const normalizedBase = base.endsWith('/') ? base.slice(0, -1) : base;
  return locale === DEFAULT_LOCALE
    ? `${normalizedBase}/`
    : `${normalizedBase}/${locale}/`;
}
