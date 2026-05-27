import React, { useState } from 'react';
import { SaleData, SaleVehicleData } from '../../types/sale';
import { useCurrency } from '../../context/CurrencyContext';
import { useLocale } from '../../context/LocaleContext';
import { SaleHeader } from './SaleHeader';
import { VehiclePreview } from './VehiclePreview';
import { VehicleSpecsGrid } from './VehicleSpecsGrid';
import { SalePriceForm } from './SalePriceForm';
import { DealerFeeSummary } from './DealerFeeSummary';
import { SellerObservationBox } from './SellerObservationBox';
import { SaleActions } from './SaleActions';
import { 
  Dialog, 
  DialogContent, 
  DialogHeader, 
  DialogTitle, 
  DialogDescription,
  DialogFooter
} from '../ui/dialog';
import { Button } from '../ui/button';
import { ColorPicker } from '../ui/ColorPicker';
import { Palette, X } from 'lucide-react';
import { cn } from '@/lib/utils';

interface VehicleSaleTabletProps {
  data: SaleData;
  price: string;
  setPrice: (val: string) => void;
  description: string;
  setDescription: (val: string) => void;
  vehicleState: SaleVehicleData;
  setVehicleState: React.Dispatch<React.SetStateAction<SaleVehicleData | null>>;
  onConfirm: (price: number, description: string, vehicleUpdates: SaleVehicleData) => void;
  onCancel: () => void;
}

export const VehicleSaleTablet: React.FC<VehicleSaleTabletProps> = ({ 
  data, 
  price, 
  setPrice, 
  description, 
  setDescription, 
  vehicleState, 
  setVehicleState, 
  onConfirm, 
  onCancel 
}) => {
  const [showConfirm, setShowConfirm] = useState(false);
  const [showColorPicker, setShowColorPicker] = useState(false);
  const [showPhotoMenu, setShowPhotoMenu] = useState(false);
  const [customImageUrl, setCustomImageUrl] = useState('');
  const feePercentage = data.dealerFee;

  const numericPrice = parseInt(price) || 0;
  const isValid = numericPrice > 0 && !!vehicleState.photoUrl;

  const handleUpdateVehicle = (updates: Partial<SaleVehicleData>) => {
    setVehicleState(prev => {
      if (!prev) return prev;
      return { ...prev, ...updates };
    });
  };

  const handleConfirm = () => {
    onConfirm(numericPrice, description, vehicleState);
  };

  const { formatPrice: format } = useCurrency();
  const { t } = useLocale();

  return (
    <div 
      className="relative w-[950px] h-[650px] bg-zinc-950 rounded-[40px] border-[12px] border-zinc-900 shadow-[0_0_80px_rgba(0,0,0,0.8)] overflow-hidden flex flex-col p-8 pb-10 select-none"
      style={{ transform: 'translate3d(0, 0, 0)' }}
    >
      {/* Local Color Picker Overlay (Notification Style) */}
      {showColorPicker && (
        <div className="absolute inset-0 z-[100] flex items-center justify-center p-8 animate-in fade-in duration-300">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-md rounded-[28px]" onClick={() => setShowColorPicker(false)} />
          <div className="relative bg-zinc-950 border border-zinc-800 p-6 rounded-3xl shadow-2xl w-full max-w-sm animate-in zoom-in-95 duration-300">
              <div className="flex items-center space-x-3 mb-4">
                <Palette size={20} className="text-concessionaire" />
                <h3 className="text-lg font-black uppercase tracking-tighter text-white">{t('paint_config')}</h3>
             </div>
             <ColorPicker 
                color={vehicleState.colorRGB || '#FFFFFF'} 
                onChange={(c) => handleUpdateVehicle({ colorRGB: c, color: 'Personalizada' })} 
             />
             <Button 
                onClick={() => setShowColorPicker(false)}
                className="w-full mt-6 bg-concessionaire hover:bg-concessionaire/90 text-white font-black uppercase text-[10px] tracking-widest h-12"
             >
                {t('apply_paint')}
             </Button>
          </div>
        </div>
      )}

      {/* Front camera and sensors simulation */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-zinc-900 rounded-b-2xl flex items-center justify-center space-x-2 z-50">
        <div className="w-2 h-2 rounded-full bg-zinc-800"></div>
        <div className="w-1.5 h-1.5 rounded-full bg-zinc-950"></div>
      </div>

      <div className={cn("flex flex-col h-full transition-all duration-500", showColorPicker && "blur-sm scale-[0.98] opacity-50 pointer-events-none")}>
        <SaleHeader bizName={data.bizName} sellerName={`${data.sellerData.firstname} ${data.sellerData.lastname}`} />
        
        <div className="flex-1 grid grid-cols-2 gap-4 mt-2">
          {/* Left Side: Preview and Info */}
          <div className="flex flex-col h-full">
            <div className="space-y-4">
              <VehiclePreview 
                model={vehicleState.model} 
                photoUrl={vehicleState.photoUrl} 
                onTakePhoto={() => setShowPhotoMenu(true)}
              />
              <VehicleSpecsGrid vehicle={vehicleState} onUpdate={handleUpdateVehicle} onOpenColorPicker={() => setShowColorPicker(true)} />
            </div>
          </div>

          {/* Right Side: Form and Summary */}
          <div className="flex flex-col h-full overflow-hidden">
            <div className="space-y-4">
              <SalePriceForm value={price} onChange={setPrice} />
              <SellerObservationBox value={description} onChange={setDescription} />
              {feePercentage > 0 && <DealerFeeSummary price={numericPrice} feePercentage={feePercentage} />}
            </div>
            <div className="mt-auto pb-2">
              <SaleActions 
                onConfirm={() => setShowConfirm(true)} 
                isValid={isValid} 
              />
            </div>
          </div>
        </div>
      </div>

      {/* Confirmation Overlay (Notification Style) */}
      {showConfirm && (
        <div className="absolute inset-0 z-[110] flex items-center justify-center p-8 animate-in fade-in duration-300">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-md rounded-[28px]" onClick={() => setShowConfirm(false)} />
          <div className="relative bg-zinc-950 border border-zinc-800 p-8 rounded-3xl shadow-2xl w-full max-w-md animate-in zoom-in-95 duration-300">
             <div className="flex items-center justify-between mb-4">
                <h3 className="text-xl font-black uppercase tracking-tighter text-white">{t('confirm_publish')}</h3>
                <button onClick={() => setShowConfirm(false)} className="text-zinc-600 hover:text-white transition-colors">
                   <X size={20} />
                </button>
             </div>
             
             <p className="text-zinc-500 text-sm mb-6 leading-relaxed" dangerouslySetInnerHTML={{
                __html: t('publish_desc_confirm').replace('%s', `<span class="text-white font-bold">${data.vehicleData.model.toUpperCase()}</span>`).replace('%s', data.vehicleData.plate)
             }} />

             <div className="bg-zinc-900 p-5 rounded-2xl space-y-3 border border-zinc-800 shadow-inner">
                <div className="flex justify-between text-[10px]">
                  <span className="text-zinc-500 uppercase font-black tracking-tighter">{t('sale_price')}</span>
                  <span className="text-white font-black">{format(numericPrice)}</span>
                </div>
                {feePercentage > 0 && (
                  <div className="flex justify-between text-[10px]">
                    <span className="text-zinc-500 uppercase font-black tracking-tighter">{t('dealer_fee')} ({feePercentage}%)</span>
                    <span className="text-red-400 font-bold">-{format(numericPrice * (feePercentage/100))}</span>
                  </div>
                )}
                <div className="h-px bg-zinc-800/50 my-1" />
                <div className="flex justify-between text-xs">
                  <span className="text-zinc-400 uppercase font-black tracking-tighter">{t('final_receive')}</span>
                  <span className="text-concessionaire font-black text-sm">{format(numericPrice - (numericPrice * (feePercentage/100)))}</span>
                </div>
             </div>

              <div className="flex space-x-3 mt-6">
                <button 
                  onClick={() => setShowConfirm(false)}
                  className="flex-1 bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 text-zinc-400 font-black uppercase text-[10px] tracking-widest h-14 rounded-xl transition-all"
                >
                  {t('sell_back_review')}
                </button>
                <button 
                  onClick={() => {
                    setShowConfirm(false);
                    handleConfirm();
                  }}
                  className="flex-[2] bg-concessionaire hover:bg-concessionaire/90 text-white font-black uppercase text-[10px] tracking-widest h-14 rounded-xl transition-all"
                >
                  {t('publish_ad')}
                </button>
             </div>
          </div>
        </div>
      )}

      {/* Photo Menu Overlay */}
      {showPhotoMenu && (
        <div className="absolute inset-0 z-[110] flex items-center justify-center p-8 animate-in fade-in duration-300">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-md rounded-[28px]" onClick={() => setShowPhotoMenu(false)} />
          <div className="relative bg-zinc-950 border border-zinc-800 p-8 rounded-3xl shadow-2xl w-full max-w-md animate-in zoom-in-95 duration-300">
             <div className="flex items-center justify-between mb-4">
                <h3 className="text-xl font-black uppercase tracking-tighter text-white">{t('photo_menu_title') || 'Opções de Imagem'}</h3>
                <button onClick={() => setShowPhotoMenu(false)} className="text-zinc-600 hover:text-white transition-colors">
                   <X size={20} />
                </button>
             </div>
             
             <div className="space-y-3 mt-4">
               {/* Option 1: Camera */}
               <button 
                 onClick={() => {
                   setShowPhotoMenu(false);
                   fetch(`https://${(window as any).GetParentResourceName?.() || 'qbx_vehiclesales'}/startVehicleCamera`, {
                     method: 'POST',
                     headers: { 'Content-Type': 'application/json' },
                     body: JSON.stringify({ plate: vehicleState.plate })
                   });
                 }}
                 className="w-full bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 text-white font-bold uppercase text-[12px] tracking-widest h-12 rounded-xl transition-all"
               >
                 {t('photo_menu_camera') || 'Câmera do Jogo'}
               </button>

               {/* Option 2: Sem Foto */}
               <button 
                 onClick={() => {
                   setShowPhotoMenu(false);
                   handleUpdateVehicle({ photoUrl: '' });
                 }}
                 className="w-full bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 text-zinc-400 font-bold uppercase text-[12px] tracking-widest h-12 rounded-xl transition-all"
               >
                 {t('photo_menu_none') || 'Sem Foto'}
               </button>

               <div className="h-px bg-zinc-800/50 my-4" />

               {/* Option 3: Link/URL */}
               <div className="space-y-2">
                 <label className="text-[10px] font-black text-zinc-500 uppercase tracking-widest pl-1">{t('photo_menu_url') || 'Link da Imagem (URL)'}</label>
                 <div className="flex gap-2">
                   <input
                     type="text"
                     value={customImageUrl}
                     onChange={(e) => setCustomImageUrl(e.target.value)}
                     placeholder={t('photo_menu_url_placeholder') || 'https://...'}
                     className="flex-1 bg-zinc-900 border border-zinc-800 text-white text-sm rounded-xl px-4 py-2 focus:outline-none focus:border-concessionaire"
                   />
                   <button 
                     onClick={() => {
                       if(customImageUrl.trim().length > 0) {
                         handleUpdateVehicle({ photoUrl: customImageUrl.trim() });
                         setShowPhotoMenu(false);
                       }
                     }}
                     className="bg-concessionaire hover:bg-concessionaire/90 text-white font-bold uppercase text-[10px] tracking-widest px-4 rounded-xl transition-all"
                   >
                     {t('photo_menu_url_confirm') || 'Aplicar Link'}
                   </button>
                 </div>
               </div>
             </div>
          </div>
        </div>
      )}

    </div>
  );
};
