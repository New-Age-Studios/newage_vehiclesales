import React from 'react';
import { SellerData } from '../../types/contract';
import { Separator } from '../ui/separator';
import { useLocale } from '../../context/LocaleContext';

interface SellerInfoProps {
  seller: SellerData;
}

export const SellerInfo: React.FC<SellerInfoProps> = ({ seller }) => {
  const { t } = useLocale();
  return (
    <div className="space-y-2">
      <div className="flex items-center space-x-2">
        <h2 className="text-[9px] font-black text-zinc-800 uppercase tracking-widest whitespace-nowrap">{t('contract_owner_info')}</h2>
        <Separator className="bg-zinc-200" />
      </div>
      
      <div className="grid grid-cols-3 gap-4">
        <div className="flex flex-col border-b border-zinc-100 pb-0.5">
          <span className="text-[8px] font-bold text-zinc-400 uppercase tracking-tighter">{t('contract_full_name')}</span>
          <span className="text-[11px] font-black text-zinc-900 uppercase">{seller.firstname} {seller.lastname}</span>
        </div>
        <div className="flex flex-col border-b border-zinc-100 pb-0.5">
          <span className="text-[8px] font-bold text-zinc-400 uppercase tracking-tighter">{t('contract_contact')}</span>
          <span className="text-[11px] font-black text-zinc-900">{seller.phone}</span>
        </div>
        <div className="flex flex-col border-b border-zinc-100 pb-0.5">
          <span className="text-[8px] font-bold text-zinc-400 uppercase tracking-tighter">{t('contract_bank_account')}</span>
          <span className="text-[11px] font-black text-zinc-900 font-mono">{seller.account}</span>
        </div>
      </div>
    </div>
  );
};
