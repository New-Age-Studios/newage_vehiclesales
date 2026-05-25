import React, { createContext, useContext } from 'react';

type Translations = Record<string, string>;

interface LocaleContextType {
  t: (key: string) => string;
}

const LocaleContext = createContext<LocaleContextType>({
  t: (key) => key, // Fallback to returning the key if context is not provided
});

interface LocaleProviderProps {
  translations: Translations;
  children: React.ReactNode;
}

export const LocaleProvider: React.FC<LocaleProviderProps> = ({ translations, children }) => {
  const t = (key: string) => {
    return translations[key] || key;
  };

  return (
    <LocaleContext.Provider value={{ t }}>
      {children}
    </LocaleContext.Provider>
  );
};

export const useLocale = () => useContext(LocaleContext);
