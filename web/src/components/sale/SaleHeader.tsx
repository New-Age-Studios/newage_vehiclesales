import React from 'react';
import { Tablet, Wifi, BatteryMedium, User } from 'lucide-react';
import { useLocale } from '../../context/LocaleContext';

interface SaleHeaderProps {
  bizName: string;
  sellerName: string;
}

export const SaleHeader: React.FC<SaleHeaderProps> = ({ bizName, sellerName }) => {
  const t = useLocale();
  return (
    <div className="flex flex-col space-y-4 mb-6">
      <div className="flex justify-between items-center text-zinc-500">
        <div className="flex items-center space-x-2">
          <Tablet size={16} />
          <span className="text-[10px] font-bold uppercase tracking-widest">{t.saleHeader.portalVersion}</span>
        </div>
        <div className="flex items-center space-x-3">
          <Wifi size={14} />
          <BatteryMedium size={14} />
          <span className="text-[10px] font-bold">21:42</span>
        </div>
      </div>
      
      <div className="flex justify-between items-end border-b border-zinc-800 pb-4">
        <div>
          <h1 className="text-2xl font-black text-white tracking-tighter uppercase">{bizName}</h1>
          <p className="text-zinc-500 text-xs font-medium">{t.saleHeader.newVehicleListing}</p>
        </div>
        <div className="flex items-center space-x-2 bg-zinc-900 px-3 py-1.5 rounded-lg border border-zinc-800">
          <User size={14} className="text-concessionaire" />
          <span className="text-[10px] font-bold text-zinc-300 uppercase">{sellerName}</span>
        </div>
      </div>
    </div>
  );
};
