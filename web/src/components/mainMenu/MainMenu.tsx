import React, { useState } from 'react';
import { Car, Coins, X, ArrowRight, FileText } from 'lucide-react';
import { useCurrency } from '../../context/CurrencyContext';
import { useLocale } from '../../context/LocaleContext';

interface MenuOption {
  title: string;
  desc: string;
}

export interface MenuData {
  bizName: string;
  enableSellBack?: boolean;
  options: {
    sell: MenuOption;
    history?: MenuOption;
    sellBack: MenuOption;
  };
  vehicleData?: {
    name: string;
    plate: string;
    price: number;
    payout: number;
    percentage: number;
    isOwned: boolean;
    hasFinancing: boolean;
  };
}

interface MainMenuProps {
  data: MenuData;
  onSelectSell: () => void;
  onSelectSellBack: () => void;
  onSelectHistory: () => void;
  onCancel: () => void;
}

export const MainMenu: React.FC<MainMenuProps> = ({
  data,
  onSelectSell,
  onSelectSellBack,
  onSelectHistory,
  onCancel,
}) => {
  const [showConfirm, setShowConfirm] = useState(false);
  const { formatPrice: format } = useCurrency();
  const t = useLocale();

  return (
    <div 
      className="w-[520px] bg-zinc-950/95 border border-zinc-800 rounded-[32px] p-8 shadow-[0_0_80px_rgba(0,0,0,0.8)] flex flex-col space-y-6 relative select-none overflow-hidden animate-in fade-in zoom-in-95 duration-300"
      style={{ transform: 'translate3d(0, 0, 0)' }}
    >
      
      {!showConfirm ? (
        <>
          {/* Top Header */}
          <div className="flex justify-between items-start border-b border-zinc-800/80 pb-5">
            <div>
              <h1 className="text-2xl font-black text-white tracking-tighter uppercase">
                {data.bizName}
              </h1>
              <p className="text-zinc-500 text-xs font-semibold uppercase tracking-wider mt-1">
                {t.mainMenu.ownerOptions}
              </p>
            </div>
            <button 
              onClick={onCancel} 
              className="p-2 rounded-full bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 hover:border-zinc-700 text-zinc-400 hover:text-white transition-all active:scale-90 focus:outline-none"
            >
              <X size={18} />
            </button>
          </div>

          {/* Options Body */}
          <div className="flex flex-col space-y-4">
            
            {/* Option 1: Sell to Player */}
            <button
              onClick={onSelectSell}
              className="group flex items-center justify-between p-5 rounded-2xl bg-zinc-900/60 border border-zinc-800/80 hover:border-concessionaire/50 hover:bg-zinc-900 hover:shadow-[0_0_20px_rgba(22,101,52,0.1)] transition-all duration-300 text-left active:scale-[0.98] focus:outline-none"
            >
              <div className="flex items-center space-x-5">
                <div className="p-3.5 rounded-xl bg-concessionaire/10 border border-concessionaire/20 group-hover:bg-concessionaire/20 group-hover:border-concessionaire/30 text-concessionaire transition-all duration-300">
                  <Car size={26} />
                </div>
                <div>
                  <h3 className="text-lg font-black text-white uppercase tracking-tight group-hover:text-concessionaire transition-colors duration-300">
                    {data.options.sell.title}
                  </h3>
                  <p className="text-zinc-400 text-xs mt-1 font-medium leading-relaxed max-w-[280px]">
                    {data.options.sell.desc}
                  </p>
                </div>
              </div>
              <div className="p-2 rounded-lg bg-zinc-950 text-zinc-600 group-hover:bg-concessionaire group-hover:text-white transition-all duration-300">
                <ArrowRight size={16} />
              </div>
            </button>

            {/* Option 2: My Listings & History */}
            {data.options.history && (
              <button
                onClick={onSelectHistory}
                className="group flex items-center justify-between p-5 rounded-2xl bg-zinc-900/60 border border-zinc-800/80 hover:border-concessionaire/50 hover:bg-zinc-900 hover:shadow-[0_0_20px_rgba(22,101,52,0.1)] transition-all duration-300 text-left active:scale-[0.98] focus:outline-none"
              >
                <div className="flex items-center space-x-5">
                  <div className="p-3.5 rounded-xl bg-concessionaire/10 border border-concessionaire/20 group-hover:bg-concessionaire/20 group-hover:border-concessionaire/30 text-concessionaire transition-all duration-300">
                    <FileText size={26} />
                  </div>
                  <div>
                    <h3 className="text-lg font-black text-white uppercase tracking-tight group-hover:text-concessionaire transition-colors duration-300">
                      {data.options.history.title}
                    </h3>
                    <p className="text-zinc-400 text-xs mt-1 font-medium leading-relaxed max-w-[280px]">
                      {data.options.history.desc}
                    </p>
                  </div>
                </div>
                <div className="p-2 rounded-lg bg-zinc-950 text-zinc-600 group-hover:bg-concessionaire group-hover:text-white transition-all duration-300">
                  <ArrowRight size={16} />
                </div>
              </button>
            )}

            {/* Option 3: Sell Back to Dealer */}
            {data.enableSellBack && (
              <button
                onClick={() => {
                  if (data.vehicleData) {
                    setShowConfirm(true);
                  } else {
                    onSelectSellBack();
                  }
                }}
                className="group flex items-center justify-between p-5 rounded-2xl bg-zinc-900/60 border border-zinc-800/80 hover:border-concessionaire/50 hover:bg-zinc-900 hover:shadow-[0_0_20px_rgba(22,101,52,0.1)] transition-all duration-300 text-left active:scale-[0.98] focus:outline-none"
              >
                <div className="flex items-center space-x-5">
                  <div className="p-3.5 rounded-xl bg-concessionaire/10 border border-concessionaire/20 group-hover:bg-concessionaire/20 group-hover:border-concessionaire/30 text-concessionaire transition-all duration-300">
                    <Coins size={26} />
                  </div>
                  <div>
                    <h3 className="text-lg font-black text-white uppercase tracking-tight group-hover:text-concessionaire transition-colors duration-300">
                      {data.options.sellBack.title}
                    </h3>
                    <p className="text-zinc-400 text-xs mt-1 font-medium leading-relaxed max-w-[280px]">
                      {data.options.sellBack.desc}
                    </p>
                  </div>
                </div>
                <div className="p-2 rounded-lg bg-zinc-950 text-zinc-600 group-hover:bg-concessionaire group-hover:text-white transition-all duration-300">
                  <ArrowRight size={16} />
                </div>
              </button>
            )}
          </div>
        </>
      ) : (
        /* Confirmation View */
        data.vehicleData && (
          <div className="flex flex-col space-y-6">
             <div className="flex items-center justify-between border-b border-zinc-800/80 pb-5">
                <h3 className="text-xl font-black uppercase tracking-tighter text-white">{t.mainMenu.confirmSale}</h3>
                <button onClick={() => setShowConfirm(false)} className="text-zinc-600 hover:text-white transition-colors focus:outline-none">
                   <X size={20} />
                </button>
             </div>
             
             <p className="text-zinc-500 text-sm leading-relaxed">
                {t.mainMenu.sellingVehicle} <span className="text-white font-bold">{data.vehicleData.name.toUpperCase()}</span> ({data.vehicleData.plate}) {t.mainMenu.backTo}
             </p>

             {/* Error/Warning States */}
             {!data.vehicleData.isOwned ? (
               <div className="bg-red-500/10 border border-red-500/20 p-4 rounded-xl text-red-400 text-xs font-semibold leading-relaxed">
                 {t.mainMenu.warningNotOwner}
               </div>
             ) : data.vehicleData.hasFinancing ? (
               <div className="bg-red-500/10 border border-red-500/20 p-4 rounded-xl text-red-400 text-xs font-semibold leading-relaxed">
                 {t.mainMenu.warningHasFinancing}
               </div>
             ) : (
               <div className="bg-zinc-900 p-5 rounded-2xl space-y-3 border border-zinc-800 shadow-inner">
                  <div className="flex justify-between text-[10px]">
                    <span className="text-zinc-500 uppercase font-black tracking-tighter">{t.mainMenu.tableValue}</span>
                    <span className="text-white font-black">{format(data.vehicleData.price)}</span>
                  </div>
                  <div className="flex justify-between text-[10px]">
                    <span className="text-zinc-500 uppercase font-black tracking-tighter">{t.mainMenu.returnDiscount} ({100 - data.vehicleData.percentage}%)</span>
                    <span className="text-red-400 font-bold">-{format(data.vehicleData.price - data.vehicleData.payout)}</span>
                  </div>
                  <div className="h-px bg-zinc-800/50 my-1" />
                  <div className="flex justify-between text-xs">
                    <span className="text-zinc-400 uppercase font-black tracking-tighter">{t.mainMenu.amountToReceive}</span>
                    <span className="text-concessionaire font-black text-sm">{format(data.vehicleData.payout)}</span>
                  </div>
               </div>
             )}

             <div className="flex space-x-3">
                <button 
                  onClick={() => setShowConfirm(false)}
                  className="flex-1 bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 text-zinc-400 font-black uppercase text-[10px] tracking-widest h-14 rounded-xl transition-all focus:outline-none"
                >
                  {t.mainMenu.review}
                </button>
                <button 
                  disabled={!data.vehicleData.isOwned || data.vehicleData.hasFinancing}
                  onClick={() => {
                    setShowConfirm(false);
                    onSelectSellBack();
                  }}
                  className="flex-[2] bg-concessionaire disabled:bg-zinc-900 disabled:text-zinc-600 disabled:border disabled:border-zinc-800 disabled:shadow-none hover:bg-concessionaire/90 text-white font-black uppercase text-[10px] tracking-widest h-14 rounded-xl transition-all focus:outline-none"
                >
                  {t.mainMenu.sellNow}
                </button>
             </div>
          </div>
        )
      )}

    </div>
  );
};
