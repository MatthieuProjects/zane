import i18next from 'i18next';
import Backend from 'i18next-fs-backend';
import { join } from 'node:path';

i18next.use(Backend).init({
  initImmediate: false,
  fallbackLng: 'en-US',
  lng: 'en-US',
  supportedLngs: ["fr", "en-US"],
  load: 'all',
  preload: ['fr', 'en-US'],
  saveMissing: true,
  ns: ['zane-bot'],
  defaultNS: 'zane-bot',
  backend: {
    loadPath: join(__dirname, './assets/locales/{{lng}}/{{ns}}.json'),
    addPath: join(__dirname, './assets/locales/{{lng}}/{{ns}}.json'),
  },
});

