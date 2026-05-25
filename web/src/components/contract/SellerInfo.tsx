import React from 'react';
import { SellerData } from '../../types/contract';
import { Separator } from '../ui/separator';

interface SellerInfoProps {
  seller: SellerData;
}

export const SellerInfo: React.FC<SellerInfoProps> = ({ seller }) => {
  return (
    <div className="space-y-2">
      <div className="flex items-center space-x-2">
        <h2 className="text-[9px] font-black text-zinc-800 uppercase tracking-widest whitespace-nowrap">Informações do Proprietário</h2>
        <Separator className="bg-zinc-200" />
      </div>
      
      <div className="grid grid-cols-3 gap-4">
        <div className="flex flex-col border-b border-zinc-100 pb-0.5">
          <span className="text-[8px] font-bold text-zinc-400 uppercase tracking-tighter">Nome Completo</span>
          <span className="text-[11px] font-black text-zinc-900 uppercase">{seller.firstname} {seller.lastname}</span>
        </div>
        <div className="flex flex-col border-b border-zinc-100 pb-0.5">
          <span className="text-[8px] font-bold text-zinc-400 uppercase tracking-tighter">Contato</span>
          <span className="text-[11px] font-black text-zinc-900">{seller.phone}</span>
        </div>
        <div className="flex flex-col border-b border-zinc-100 pb-0.5">
          <span className="text-[8px] font-bold text-zinc-400 uppercase tracking-tighter">Conta Bancária</span>
          <span className="text-[11px] font-black text-zinc-900 font-mono">{seller.account}</span>
        </div>
      </div>
    </div>
  );
};
