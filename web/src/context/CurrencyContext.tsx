import React, { createContext, useContext } from 'react';

interface CurrencyContextType {
  currencySymbol: string;
  currencyLocale: string;
  formatPrice: (value: number) => string;
}

const CurrencyContext = createContext<CurrencyContextType>({
  currencySymbol: 'R$',
  currencyLocale: 'pt-BR',
  formatPrice: (value: number) => {
    const formattedNumber = new Intl.NumberFormat('pt-BR', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
    return `R$ ${formattedNumber}`.trim();
  }
});

interface CurrencyProviderProps {
  symbol: string;
  locale: string;
  children: React.ReactNode;
}

export const CurrencyProvider: React.FC<CurrencyProviderProps> = ({ symbol, locale, children }) => {
  const formatPrice = (value: number) => {
    const formattedNumber = new Intl.NumberFormat(locale || 'pt-BR', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
    return `${symbol || 'R$'} ${formattedNumber}`.trim();
  };

  return (
    <CurrencyContext.Provider value={{ currencySymbol: symbol, currencyLocale: locale, formatPrice }}>
      {children}
    </CurrencyContext.Provider>
  );
};

export const useCurrency = () => useContext(CurrencyContext);
