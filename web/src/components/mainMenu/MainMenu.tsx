import React from 'react';
import { Car, Coins, X, ArrowRight } from 'lucide-react';

interface MenuOption {
  title: string;
  desc: string;
}

export interface MenuData {
  bizName: string;
  enableSellBack?: boolean;
  options: {
    sell: MenuOption;
    sellBack: MenuOption;
  };
}

interface MainMenuProps {
  data: MenuData;
  onSelectSell: () => void;
  onSelectSellBack: () => void;
  onCancel: () => void;
}

export const MainMenu: React.FC<MainMenuProps> = ({
  data,
  onSelectSell,
  onSelectSellBack,
  onCancel,
}) => {
  return (
    <div className="w-[520px] bg-zinc-950/95 border border-zinc-800 rounded-[32px] p-8 shadow-[0_0_80px_rgba(0,0,0,0.8)] flex flex-col space-y-6 relative select-none animate-in fade-in zoom-in-95 duration-300">
      
      {/* Top Header */}
      <div className="flex justify-between items-start border-b border-zinc-800/80 pb-5">
        <div>
          <h1 className="text-2xl font-black text-white tracking-tighter uppercase">
            {data.bizName}
          </h1>
          <p className="text-zinc-500 text-xs font-semibold uppercase tracking-wider mt-1">
            Opções do Proprietário
          </p>
        </div>
        <button 
          onClick={onCancel} 
          className="p-2 rounded-full bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 hover:border-zinc-700 text-zinc-400 hover:text-white transition-all active:scale-90"
        >
          <X size={18} />
        </button>
      </div>

      {/* Options Body */}
      <div className="flex flex-col space-y-4">
        
        {/* Option 1: Sell to Player */}
        <button
          onClick={onSelectSell}
          className="group flex items-center justify-between p-5 rounded-2xl bg-zinc-900/60 border border-zinc-800/80 hover:border-concessionaire/50 hover:bg-zinc-900 hover:shadow-[0_0_20px_rgba(22,101,52,0.1)] transition-all duration-300 text-left active:scale-[0.98]"
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
          <div className="p-2 rounded-lg bg-zinc-950 text-zinc-600 group-hover:bg-concessionaire group-hover:text-black transition-all duration-300">
            <ArrowRight size={16} />
          </div>
        </button>

        {/* Option 2: Sell Back to Dealer */}
        {data.enableSellBack && (
          <button
            onClick={onSelectSellBack}
            className="group flex items-center justify-between p-5 rounded-2xl bg-zinc-900/60 border border-zinc-800/80 hover:border-concessionaire/50 hover:bg-zinc-900 hover:shadow-[0_0_20px_rgba(22,101,52,0.1)] transition-all duration-300 text-left active:scale-[0.98]"
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
            <div className="p-2 rounded-lg bg-zinc-950 text-zinc-600 group-hover:bg-concessionaire group-hover:text-black transition-all duration-300">
              <ArrowRight size={16} />
            </div>
          </button>
        )}

      </div>
    </div>
  );
};
