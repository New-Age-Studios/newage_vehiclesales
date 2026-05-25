import React, { createContext, useContext } from 'react';

const CURRENCY_LOCALE = 'pt-BR'; // Locale fixo: ponto como separador de milhar

interface CurrencyContextType {
  currencySymbol: string;
  currencyCode: string;
  formatPrice: (value: number) => string;
}

const CurrencyContext = createContext<CurrencyContextType>({
  currencySymbol: 'R$',
  currencyCode: 'BRL',
  formatPrice: (value: number) => {
    const formattedNumber = new Intl.NumberFormat(CURRENCY_LOCALE, {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
    return `R$ ${formattedNumber}`.trim();
  }
});

interface CurrencyProviderProps {
  symbol: string;
  code: string;
  children: React.ReactNode;
}

export const CurrencyProvider: React.FC<CurrencyProviderProps> = ({ symbol, code, children }) => {
  const formatPrice = (value: number) => {
    const formattedNumber = new Intl.NumberFormat(CURRENCY_LOCALE, {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
    return `${symbol || 'R$'} ${formattedNumber}`.trim();
  };

  return (
    <CurrencyContext.Provider value={{ currencySymbol: symbol, currencyCode: code, formatPrice }}>
      {children}
    </CurrencyContext.Provider>
  );
};

export const useCurrency = () => useContext(CurrencyContext);
