import React from 'react';

interface PriceBoxProps {
  price: number;
}

export const PriceBox: React.FC<PriceBoxProps> = ({ price }) => {
  const formattedPrice = new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
    minimumFractionDigits: 0,
  }).format(price);

  return (
    <div className="bg-concessionaire/5 border-2 border-concessionaire/20 p-3 rounded-sm mb-4 relative overflow-hidden">
      <div className="absolute top-0 left-0 w-1 h-full bg-concessionaire"></div>
      <div className="flex justify-between items-center">
        <div>
          <span className="text-[9px] font-bold text-concessionaire uppercase tracking-widest block mb-0.5">Valor Total da Transação</span>
          <div className="text-xl font-serif font-bold text-concessionaire-dark">
            {formattedPrice}
          </div>
        </div>
        <div className="text-right">
          <span className="text-[8px] font-bold text-zinc-400 uppercase block">Status</span>
          <span className="text-[9px] font-bold text-zinc-600 bg-zinc-100 px-2 py-0.5 rounded-full uppercase">Pendente</span>
        </div>
      </div>
    </div>
  );
};
