import React, { createContext, useContext, useMemo } from 'react';
import ptBRJson from '../../../locales/pt-br.json';

export type NUILocale = typeof ptBRJson.nui;
const ptBR: NUILocale = ptBRJson.nui;

// ─── Registry ─────────────────────────────────────────────────────────────────
// Locales are loaded dynamically by Lua from locales/<name>.json and passed here.
// ptBR serves as the default compile-time type schema and fallback.
const LOCALES: Record<string, NUILocale> = {
  'pt-BR': ptBR,
};

// ─── Context ──────────────────────────────────────────────────────────────────
const LocaleContext = createContext<NUILocale>(ptBR);

interface LocaleProviderProps {
  /** The locale key sent from config.lua via nuiLocale. Must match a key in LOCALES. */
  locale?: string;
  localeData?: any;
  children: React.ReactNode;
}

export const LocaleProvider: React.FC<LocaleProviderProps> = ({ locale, localeData, children }) => {
  const strings = useMemo<NUILocale>(() => {
    if (localeData) {
      return localeData as NUILocale;
    }
    if (locale && LOCALES[locale]) {
      return LOCALES[locale];
    }
    // Fallback to pt-BR if the requested locale is not registered
    return ptBR;
  }, [locale, localeData]);

  return (
    <LocaleContext.Provider value={strings}>
      {children}
    </LocaleContext.Provider>
  );
};

/** Hook to access all locale strings in any component. */
export const useLocale = (): NUILocale => useContext(LocaleContext);
