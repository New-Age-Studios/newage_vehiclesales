import React from 'react';
import { ContractData } from '../../types/contract';
import { useLocale } from '../../context/LocaleContext';

interface ContractHeaderProps {
  data: ContractData;
}

export const ContractHeader: React.FC<ContractHeaderProps> = ({ data }) => {
  const t = useLocale();
  return (
    <div className="flex flex-col items-center text-center space-y-1 mb-4">
      <div className="w-12 h-12 bg-zinc-900 flex items-center justify-center rounded-full mb-1">
         <span className="text-white font-bold text-lg">{data.bizName.charAt(0)}</span>
      </div>
      <h1 className="text-xl font-serif font-bold text-zinc-900 tracking-widest uppercase">
        {data.bizName}
      </h1>
      <div className="flex flex-col">
        <span className="text-[10px] font-bold text-zinc-700 tracking-wider">{t.contract.title}</span>
        <span className="text-[9px] text-zinc-500 font-medium tracking-tighter">{t.contract.number} {data.id}</span>
      </div>
    </div>
  );
};
