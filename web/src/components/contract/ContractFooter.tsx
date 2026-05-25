import React from 'react';
import { useLocale } from '../../context/LocaleContext';

export const ContractFooter: React.FC = () => {
  const { t } = useLocale();
  return (
    <div className="pt-4 border-t border-zinc-100 flex justify-between items-end">
      <div className="space-y-1">
        <div className="text-[9px] font-black text-zinc-900 uppercase tracking-tighter">{t('contract_authenticity')}</div>
        <div className="text-[8px] text-zinc-600 font-medium max-w-[250px] leading-tight">
          {t('contract_authenticity_desc')}
        </div>
      </div>
      
      <div className="flex flex-col items-center space-y-1">
        {/* Visual Barcode with CSS - Extended for better alignment */}
        <div className="flex space-x-[1.5px] h-7 items-end">
          {[2, 1, 3, 1, 2, 1, 4, 1, 2, 3, 1, 2, 1, 4, 1, 2, 1, 3, 2, 1, 2, 1, 3, 1, 4, 1, 2, 1, 3, 2].map((w, i) => (
            <div key={i} className="bg-zinc-800" style={{ width: `${w}px`, height: i % 5 === 0 ? '100%' : '70%' }}></div>
          ))}
        </div>
        <span className="text-[9px] font-mono text-zinc-600 font-black tracking-[0.25em] leading-none">
          8172-X921-BA02-5512
        </span>
      </div>
    </div>
  );
};
