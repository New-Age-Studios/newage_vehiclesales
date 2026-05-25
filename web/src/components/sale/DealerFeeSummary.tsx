import React from 'react';
import { Info } from 'lucide-react';
import { useCurrency } from '../../context/CurrencyContext';

interface DealerFeeSummaryProps {
  price: number;
  feePercentage: number;
}

export const DealerFeeSummary: React.FC<DealerFeeSummaryProps> = ({ price, feePercentage }) => {
  const feeValue = price * (feePercentage / 100);
  const netValue = price - feeValue;

  const { formatPrice: format } = useCurrency();

  return (
    <div className="bg-zinc-900/80 border border-zinc-800 p-4 rounded-xl space-y-3">
      <div className="flex items-center space-x-2 text-zinc-500 mb-1">
        <Info size={14} />
        <span className="text-[10px] font-bold uppercase tracking-widest">Resumo Financeiro</span>
      </div>
      
      <div className="space-y-2">
        <div className="flex justify-between items-center text-xs">
          <span className="text-zinc-400">Taxa Administrativa ({feePercentage}%)</span>
          <span className="text-zinc-200 font-bold">{format(feeValue)}</span>
        </div>
        <div className="h-px bg-zinc-800" />
        <div className="flex justify-between items-center">
          <span className="text-zinc-400 text-xs font-bold uppercase tracking-tighter">Valor Líquido a Receber</span>
          <span className="text-xl font-black text-white">{format(netValue)}</span>
        </div>
      </div>
      
      <p className="text-[9px] text-zinc-600 italic leading-tight">
        * O valor líquido será depositado em sua conta bancária assim que o veículo for vendido.
      </p>
    </div>
  );
};
