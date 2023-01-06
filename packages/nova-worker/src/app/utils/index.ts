import { Locale } from 'discord-api-types/v10';
import i18next from 'i18next';

let locales = [];
for (const locale in Locale) {
  locales.push(Locale[locale]);
}

export function generateLanguageMap(key: string | string[]): Record<string, string> {
  const languageMap: Record<string, string> = {};
  
  for (const language of locales) {
    if (locales.includes(language))
      languageMap[language] = i18next.t(key, { lng: language });
  }

  return languageMap;
}
