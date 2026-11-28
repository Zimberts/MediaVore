# MediaVore Showcase Website

Static Astro site deployed to GitHub Pages at <https://zimberts.github.io/MediaVore/>.

## Local development

```bash
cd site
npm ci
npm run dev
```

## Checks & build

```bash
npm run check      # TypeScript & Astro diagnostics
npm test           # Unit tests + i18n key parity check
npm run build      # Static build into dist/
```

## Adding a new language

1. Copy `src/i18n/en.json` to `src/i18n/<code>.json` and translate all values.
2. Import it and add an entry in `LOCALES` inside `src/i18n/index.ts`.
3. Add `<code>` to `i18n.locales` in `astro.config.mjs`.
4. Add `src/pages/<code>/index.astro` rendering `<LandingPage locale="<code>" />`.
5. Run `npm test && npm run check && npm run build` to verify key parity and static output.
