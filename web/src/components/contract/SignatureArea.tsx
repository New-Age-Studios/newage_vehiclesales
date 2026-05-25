import React from 'react';
import { SellerData } from '../../types/contract';

interface SignatureAreaProps {
  seller: SellerData;
  buyerName?: string;
  date: string;
  onSign: () => void;
  isSigned: boolean;
}

export const SignatureArea: React.FC<SignatureAreaProps> = ({ seller, buyerName = "Aguardando...", date, onSign, isSigned }) => {
  return (
    <div className="space-y-4 mb-2">
      <div className="grid grid-cols-2 gap-8">
        <div className="flex flex-col items-center">
          <div className="w-full border-b border-zinc-300 mb-1 h-8 flex items-end justify-center">
             <span className="font-['Alex_Brush'] text-zinc-500 text-2xl opacity-80 select-none leading-none mb-[-2px]">
                {seller.firstname} {seller.lastname}
             </span>
          </div>
          <span className="text-[9px] font-bold text-zinc-500 uppercase tracking-tighter">VENDEDOR</span>
        </div>
        
        <div className="flex flex-col items-center">
          <div 
            onClick={onSign}
            className={`w-full border-b border-zinc-300 mb-1 h-8 flex items-end justify-center transition-all duration-300 ${!isSigned ? 'cursor-pointer hover:bg-concessionaire/5 group' : ''}`}
          >
             {!isSigned ? (
               <span className="text-[8px] font-bold text-concessionaire uppercase tracking-widest animate-pulse group-hover:scale-110 transition-transform">
                 [ Clique para Assinar ]
               </span>
             ) : (
               <span className="font-['Alex_Brush'] text-concessionaire text-2xl select-none animate-signature leading-none mb-[-2px]">
                 {buyerName || "Assinado"}
               </span>
             )}
          </div>
          <span className="text-[9px] font-bold text-zinc-500 uppercase tracking-tighter">COMPRADOR</span>
        </div>
      </div>
      
      <div className="text-center">
        <span className="text-[8px] text-zinc-400 font-medium">
          Doc: {date}
        </span>
      </div>
    </div>
  );
};
