import React from 'react';
import { Input } from '../ui/input';
import { Banknote } from 'lucide-react';

interface SalePriceFormProps {
  value: string;
  onChange: (value: string) => void;
}

export const SalePriceForm: React.FC<SalePriceFormProps> = ({ value, onChange }) => {
  const formatCurrency = (val: string) => {
    const cleanValue = val.replace(/\D/g, "");
    const numericValue = parseInt(cleanValue) || 0;
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(numericValue);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const rawValue = e.target.value.replace(/\D/g, "");
    onChange(rawValue);
  };

  return (
    <div className="space-y-2">
      <label className="text-[10px] font-black text-zinc-400 uppercase tracking-widest flex items-center space-x-2">
        <Banknote size={12} className="text-concessionaire" />
        <span>Valor de Venda Pretendido</span>
      </label>
      <div className="relative">
        <Input 
          value={formatCurrency(value)}
          onChange={handleChange}
          placeholder="R$ 0"
          className="bg-zinc-900 border-zinc-800 h-12 text-xl font-black text-concessionaire placeholder:text-zinc-800"
        />
        <div className="absolute right-4 top-1/2 -translate-y-1/2 text-[10px] font-black text-zinc-600 uppercase tracking-tighter pointer-events-none">
          BRL / Moeda Local
        </div>
      </div>
    </div>
  );
};
