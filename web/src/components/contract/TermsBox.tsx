import React from 'react';
import { useLocale } from '../../context/LocaleContext';

export const TermsBox: React.FC = () => {
  const t = useLocale();
  return (
    <div className="space-y-3 mb-4">
      <h3 className="text-[10px] font-black text-zinc-900 uppercase tracking-widest border-b border-zinc-100 pb-1">{t.contract.termsTitle}</h3>
      <div className="text-[10px] text-zinc-600 leading-normal text-justify space-y-1.5 font-medium">
        <p>{t.contract.terms1}</p>
        <p>{t.contract.terms2}</p>
      </div>
    </div>
  );
};
