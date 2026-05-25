import React, { useState } from 'react';
import { ActiveListing, SoldVehicle } from '../../types/history';
import { X, Calendar, User, FileText, ArrowLeft, RefreshCw, Car, Coins, Tag, Receipt } from 'lucide-react';
import { Button } from '../ui/button';
import { cn } from '@/lib/utils';

export interface HistoryTabletData {
  bizName: string;
  active: ActiveListing[];
  sold: SoldVehicle[];
  sellerData: {
    firstname: string;
    lastname: string;
    account: string;
    phone: string;
  };
}

interface VehicleHistoryTabletProps {
  data: HistoryTabletData;
  onCancelSale: (listing: ActiveListing) => void;
  onCancel: () => void;
  onOpenContract: (sold: SoldVehicle) => void;
}

export const VehicleHistoryTablet: React.FC<VehicleHistoryTabletProps> = ({
  data,
  onCancelSale,
  onCancel,
  onOpenContract,
}) => {
  const [activeTab, setActiveTab] = useState<'active' | 'sold'>('active');
  const [selectedActive, setSelectedActive] = useState<ActiveListing | null>(data.active?.[0] || null);
  const [selectedSold, setSelectedSold] = useState<SoldVehicle | null>(data.sold?.[0] || null);

  const formatPrice = (val: number) =>
    new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val);

  const getPhotoUrl = (model: string) =>
    `https://raw.githubusercontent.com/mriqbox/ui-kit/main/assets/vehicles/${model.toLowerCase()}.jpg`;

  const handleTabChange = (tab: 'active' | 'sold') => {
    setActiveTab(tab);
    if (tab === 'active') {
      setSelectedActive(data.active?.[0] || null);
    } else {
      setSelectedSold(data.sold?.[0] || null);
    }
  };

  return (
    <div className="relative w-[950px] h-[650px] bg-zinc-950 rounded-[40px] border-[12px] border-zinc-900 shadow-[0_0_80px_rgba(0,0,0,0.8)] overflow-hidden flex flex-col p-8 pb-10 select-none" style={{ transform: 'translate3d(0, 0, 0)' }}>
      
      {/* Front camera and sensors simulation */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-zinc-900 rounded-b-2xl flex items-center justify-center space-x-2 z-50">
        <div className="w-2 h-2 rounded-full bg-zinc-800"></div>
        <div className="w-1.5 h-1.5 rounded-full bg-zinc-950"></div>
      </div>

      {/* Header */}
      <div className="flex justify-between items-start border-b border-zinc-800 pb-5 mb-5">
        <div>
          <h1 className="text-2xl font-black text-white tracking-tighter uppercase flex items-center gap-2">
            <RefreshCw size={24} className="text-concessionaire" /> {data.bizName}
          </h1>
          <p className="text-zinc-500 text-xs font-semibold uppercase tracking-wider mt-1">
            Minhas Vendas e Histórico • {data.sellerData.firstname} {data.sellerData.lastname}
          </p>
        </div>
        <button 
          onClick={onCancel} 
          className="p-2 rounded-full bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 hover:border-zinc-700 text-zinc-400 hover:text-white transition-all active:scale-90 focus:outline-none"
        >
          <X size={18} />
        </button>
      </div>

      {/* Main Body Grid */}
      <div className="flex-1 grid grid-cols-12 gap-6 overflow-hidden">
        
        {/* Left Column: Tabs and List (7 Cols) */}
        <div className="col-span-7 flex flex-col h-full overflow-hidden space-y-4">
          {/* Tab buttons */}
          <div className="flex bg-zinc-900/60 p-1.5 rounded-2xl border border-zinc-800/80">
            <button
              onClick={() => handleTabChange('active')}
              className={cn(
                "flex-1 py-3 px-4 rounded-xl font-black uppercase text-[10px] tracking-widest transition-all duration-300 focus:outline-none flex items-center justify-center gap-2",
                activeTab === 'active' 
                  ? "bg-concessionaire text-white shadow-[0_4px_12px_rgba(22,101,52,0.2)]" 
                  : "text-zinc-400 hover:text-white hover:bg-zinc-800/40"
              )}
            >
              <Tag size={14} /> Anúncios Ativos ({data.active?.length || 0})
            </button>
            <button
              onClick={() => handleTabChange('sold')}
              className={cn(
                "flex-1 py-3 px-4 rounded-xl font-black uppercase text-[10px] tracking-widest transition-all duration-300 focus:outline-none flex items-center justify-center gap-2",
                activeTab === 'sold' 
                  ? "bg-concessionaire text-white shadow-[0_4px_12px_rgba(22,101,52,0.2)]" 
                  : "text-zinc-400 hover:text-white hover:bg-zinc-800/40"
              )}
            >
              <Receipt size={14} /> Veículos Vendidos ({data.sold?.length || 0})
            </button>
          </div>

          {/* List area */}
          <div className="flex-1 overflow-y-auto pr-1 space-y-3 custom-scrollbar">
            {activeTab === 'active' ? (
              data.active && data.active.length > 0 ? (
                data.active.map((listing, idx) => (
                  <button
                    key={listing.oid || idx}
                    onClick={() => setSelectedActive(listing)}
                    className={cn(
                      "w-full text-left flex items-center p-4 rounded-2xl border transition-all duration-300 focus:outline-none group",
                      selectedActive?.oid === listing.oid
                        ? "bg-zinc-900/80 border-concessionaire/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]"
                        : "bg-zinc-900/30 border-zinc-800/60 hover:bg-zinc-900/60 hover:border-zinc-700/60"
                    )}
                  >
                    <img 
                      src={listing.photoUrl || getPhotoUrl(listing.model)}
                      alt={listing.model}
                      className="w-16 h-10 object-cover rounded-lg border border-zinc-800 group-hover:scale-105 transition-transform duration-300 mr-4"
                      onError={(e) => {
                        (e.target as HTMLImageElement).src = 'https://raw.githubusercontent.com/mriqbox/ui-kit/main/assets/vehicles/default.jpg';
                      }}
                    />
                    <div className="flex-1 min-w-0">
                      <h4 className="text-sm font-black text-white uppercase tracking-tight truncate group-hover:text-concessionaire transition-colors">
                        {listing.model.toUpperCase()}
                      </h4>
                      <p className="text-zinc-500 text-[10px] font-bold uppercase tracking-wider mt-0.5">
                        Placa: {listing.plate}
                      </p>
                    </div>
                    <div className="text-right">
                      <span className="text-sm font-black text-concessionaire">
                        {formatPrice(listing.price)}
                      </span>
                      <p className="text-zinc-500 text-[9px] font-medium uppercase mt-0.5">
                        ID: {listing.oid}
                      </p>
                    </div>
                  </button>
                ))
              ) : (
                <div className="h-full flex flex-col items-center justify-center text-zinc-500 py-16">
                  <Car size={32} className="opacity-30 mb-2" />
                  <p className="text-xs font-semibold uppercase tracking-wider">Nenhum anúncio ativo</p>
                </div>
              )
            ) : (
              data.sold && data.sold.length > 0 ? (
                data.sold.map((soldVeh, idx) => (
                  <button
                    key={soldVeh.id || idx}
                    onClick={() => setSelectedSold(soldVeh)}
                    className={cn(
                      "w-full text-left flex items-center p-4 rounded-2xl border transition-all duration-300 focus:outline-none group",
                      selectedSold?.id === soldVeh.id
                        ? "bg-zinc-900/80 border-concessionaire/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]"
                        : "bg-zinc-900/30 border-zinc-800/60 hover:bg-zinc-900/60 hover:border-zinc-700/60"
                    )}
                  >
                    <img 
                      src={soldVeh.photoUrl || getPhotoUrl(soldVeh.model)}
                      alt={soldVeh.model}
                      className="w-16 h-10 object-cover rounded-lg border border-zinc-800 group-hover:scale-105 transition-transform duration-300 mr-4"
                      onError={(e) => {
                        (e.target as HTMLImageElement).src = 'https://raw.githubusercontent.com/mriqbox/ui-kit/main/assets/vehicles/default.jpg';
                      }}
                    />
                    <div className="flex-1 min-w-0">
                      <h4 className="text-sm font-black text-white uppercase tracking-tight truncate group-hover:text-concessionaire transition-colors">
                        {soldVeh.model.toUpperCase()}
                      </h4>
                      <p className="text-zinc-500 text-[10px] font-bold uppercase tracking-wider mt-0.5">
                        Placa: {soldVeh.plate}
                      </p>
                    </div>
                    <div className="text-right">
                      <span className="text-sm font-black text-green-400">
                        {formatPrice(soldVeh.price)}
                      </span>
                      <p className="text-zinc-500 text-[9px] font-medium uppercase mt-0.5">
                        {new Date(soldVeh.date).toLocaleDateString('pt-BR')}
                      </p>
                    </div>
                  </button>
                ))
              ) : (
                <div className="h-full flex flex-col items-center justify-center text-zinc-500 py-16">
                  <Coins size={32} className="opacity-30 mb-2" />
                  <p className="text-xs font-semibold uppercase tracking-wider">Nenhum veículo vendido</p>
                </div>
              )
            )}
          </div>
        </div>

        {/* Right Column: Preview/Summary & Actions (5 Cols) */}
        <div className="col-span-5 flex flex-col h-full bg-zinc-900/40 border border-zinc-800/80 rounded-3xl p-6 overflow-hidden">
          {activeTab === 'active' && selectedActive ? (
            <div className="flex flex-col h-full">
              <h3 className="text-lg font-black uppercase text-white tracking-tight border-b border-zinc-800 pb-3 mb-4">
                Detalhes do Anúncio
              </h3>

              <div className="flex-1 space-y-5 overflow-y-auto pr-1 custom-scrollbar">
                <img 
                  src={selectedActive.photoUrl || getPhotoUrl(selectedActive.model)} 
                  alt={selectedActive.model}
                  className="w-full h-32 object-cover rounded-xl border border-zinc-800"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = 'https://raw.githubusercontent.com/mriqbox/ui-kit/main/assets/vehicles/default.jpg';
                  }}
                />

                <div className="space-y-3">
                  <div>
                    <span className="text-[10px] font-black uppercase tracking-widest text-zinc-500 block">Veículo</span>
                    <span className="text-white font-black text-base uppercase leading-none">{selectedActive.model}</span>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <span className="text-[10px] font-black uppercase tracking-widest text-zinc-500 block">Placa</span>
                      <span className="text-zinc-300 font-bold uppercase text-xs">{selectedActive.plate}</span>
                    </div>
                    <div>
                      <span className="text-[10px] font-black uppercase tracking-widest text-zinc-500 block">Preço Cobrado</span>
                      <span className="text-concessionaire font-black text-sm">{formatPrice(selectedActive.price)}</span>
                    </div>
                  </div>
                  {selectedActive.description && (
                    <div>
                      <span className="text-[10px] font-black uppercase tracking-widest text-zinc-500 block">Descrição do Vendedor</span>
                      <p className="text-zinc-400 text-xs italic bg-zinc-950/40 border border-zinc-800/60 p-3 rounded-xl mt-1 leading-relaxed">
                        "{selectedActive.description}"
                      </p>
                    </div>
                  )}
                </div>
              </div>

              <div className="mt-auto pt-4 border-t border-zinc-800/80">
                <Button 
                  onClick={() => onCancelSale(selectedActive)}
                  className="w-full bg-red-600 hover:bg-red-700 text-white font-black uppercase text-[10px] tracking-widest h-14 rounded-xl focus:outline-none"
                >
                  Cancelar Anúncio
                </Button>
                <p className="text-[9px] text-zinc-500 text-center uppercase font-bold tracking-wider mt-2">
                  O veículo será devolvido à sua garagem.
                </p>
              </div>
            </div>
          ) : activeTab === 'sold' && selectedSold ? (
            <div className="flex flex-col h-full">
              <h3 className="text-lg font-black uppercase text-white tracking-tight border-b border-zinc-800 pb-3 mb-4">
                Detalhes da Venda
              </h3>

              <div className="flex-1 space-y-4 overflow-y-auto pr-1 custom-scrollbar">
                <img 
                  src={selectedSold.photoUrl || getPhotoUrl(selectedSold.model)} 
                  alt={selectedSold.model}
                  className="w-full h-32 object-cover rounded-xl border border-zinc-800"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = 'https://raw.githubusercontent.com/mriqbox/ui-kit/main/assets/vehicles/default.jpg';
                  }}
                />

                <div className="space-y-3 bg-zinc-950/40 border border-zinc-800/60 p-4 rounded-2xl">
                  <div className="flex items-center gap-2 border-b border-zinc-800/50 pb-2">
                    <User size={16} className="text-concessionaire" />
                    <div className="flex-1 min-w-0">
                      <span className="text-[8px] font-black uppercase tracking-wider text-zinc-500 block">Comprador</span>
                      <span className="text-white font-black text-xs truncate block">{selectedSold.buyerName}</span>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 border-b border-zinc-800/50 pb-2">
                    <Calendar size={16} className="text-concessionaire" />
                    <div>
                      <span className="text-[8px] font-black uppercase tracking-wider text-zinc-500 block">Data da Transação</span>
                      <span className="text-white font-bold text-xs">
                        {new Date(selectedSold.date).toLocaleString('pt-BR')}
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 pb-1">
                    <Coins size={16} className="text-concessionaire" />
                    <div>
                      <span className="text-[8px] font-black uppercase tracking-wider text-zinc-500 block">Crédito Recebido</span>
                      <span className="text-green-400 font-black text-sm">{formatPrice(selectedSold.price)}</span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="mt-auto pt-4 border-t border-zinc-800/80">
                <Button 
                  onClick={() => onOpenContract(selectedSold)}
                  className="w-full bg-concessionaire hover:bg-concessionaire/90 text-white font-black uppercase text-[10px] tracking-widest h-14 rounded-xl focus:outline-none flex items-center justify-center gap-2"
                >
                  <FileText size={16} /> Visualizar Contrato
                </Button>
              </div>
            </div>
          ) : (
            <div className="h-full flex flex-col items-center justify-center text-zinc-500 text-center py-16">
              <Car size={40} className="opacity-30 mb-3" />
              <p className="text-xs font-semibold uppercase tracking-wider max-w-[180px]">
                Selecione um veículo da lista para visualizar os detalhes
              </p>
            </div>
          )}
        </div>

      </div>
    </div>
  );
};
