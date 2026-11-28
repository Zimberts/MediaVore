import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://zimberts.github.io',
  base: '/MediaVore',
  output: 'static',
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'fr'],
    routing: {
      prefixDefaultLocale: false,
    },
  },
});
