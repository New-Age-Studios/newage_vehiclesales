import React, { useState } from 'react';
import { ContractData } from '../../types/contract';
import { ContractHeader } from './ContractHeader';
import { useLocale } from '../../context/LocaleContext';
import { VehiclePhoto } from './VehiclePhoto';
import { VehicleInfo } from './VehicleInfo';
import { SellerInfo } from './SellerInfo';
import { PriceBox } from './PriceBox';
import { TermsBox } from './TermsBox';
import { SignatureArea } from './SignatureArea';
import { ContractFooter } from './ContractFooter';
import { useCurrency } from '../../context/CurrencyContext';
import { Button } from '../ui/button';

interface VehicleContractProps {
  data: ContractData;
  onConfirm: (paymentMethod?: string) => void;
  onCancel: () => void;
  readOnly?: boolean;
}

export const VehicleContract: React.FC<VehicleContractProps> = ({ data, onConfirm, onCancel, readOnly = false }) => {
  const [isSigned, setIsSigned] = useState(readOnly);
  const [isProcessing, setIsProcessing] = useState(false);
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState<'bank' | 'cash'>('bank');
  const { t } = useLocale();
  const { formatPrice } = useCurrency();

  const handleSign = () => {
    if (readOnly || isProcessing || isSigned) return;
    setShowConfirmModal(true);
  };

  const handleConfirmSignature = () => {
    setShowConfirmModal(false);
    setIsSigned(true);
    setIsProcessing(true);
    
    // Simulate signing time before confirming
    setTimeout(() => {
      onConfirm(paymentMethod);
    }, 1500);
  };

  return (
    <div className="relative w-full h-full flex items-center justify-center p-4">
      {/* Contract Paper (A4 Proportion) */}
      <div className="contract-paper relative w-[680px] h-[900px] bg-paper paper-texture p-8 flex flex-col shadow-2xl overflow-hidden border border-zinc-300/50">
        {/* Subtle paper grain overlay */}
        <div className="absolute inset-0 opacity-[0.03] pointer-events-none bg-[url('https://www.transparenttextures.com/patterns/felt.png')]"></div>
        
        <ContractHeader data={data} />
        
        <div className="flex-1 space-y-4 overflow-hidden">
          {/* Side-by-side Photo and Main Info */}
          <div className="flex gap-6 items-start">
            <div className="w-1/3">
              <VehiclePhoto url={data.vehicle.photoUrl} model={data.vehicle.model} />
            </div>
            <div className="w-2/3">
              <VehicleInfo vehicle={data.vehicle} />
            </div>
          </div>
          
          <SellerInfo seller={data.seller} />
          
          <PriceBox price={data.vehicle.price} />
          <TermsBox />
        </div>
        
        <div className="mt-4 pt-4 border-t border-zinc-100">
          <SignatureArea 
            seller={data.seller} 
            buyerName={isSigned ? (data.buyer ? `${data.buyer.firstname} ${data.buyer.lastname}` : t('contract_authorized_buyer')) : undefined}
            date={data.date} 
            onSign={handleSign}
            isSigned={isSigned}
          />
          <ContractFooter />
        </div>

        {/* Paper-styled Confirmation Overlay */}
        {showConfirmModal && (
          <div className="absolute inset-0 bg-black/40 backdrop-blur-[2px] z-50 flex items-center justify-center p-8 transition-all duration-300">
            {/* Modal Box in Paper style */}
            <div className="relative w-full max-w-md bg-paper paper-texture border-2 border-double border-zinc-400 p-6 shadow-2xl flex flex-col items-center text-center animate-in fade-in zoom-in-95 duration-200">
              {/* Grain overlay for modal paper */}
              <div className="absolute inset-0 opacity-[0.03] pointer-events-none bg-[url('https://www.transparenttextures.com/patterns/felt.png')]"></div>
              
              <h3 className="font-serif text-lg font-bold text-zinc-800 tracking-wide uppercase border-b border-zinc-300 pb-2 w-full mb-4">
                {t('contract_confirm_title')}
              </h3>
              
              <p className="text-xs text-zinc-600 mb-6 leading-relaxed font-medium">
                {t('contract_confirm_desc')}
              </p>
              
              {/* Transaction details box */}
              <div className="w-full bg-zinc-100/40 border border-zinc-300/60 rounded p-4 mb-6 space-y-2 text-left font-sans text-xs">
                <div className="flex justify-between border-b border-zinc-200/50 pb-1.5">
                  <span className="font-bold text-zinc-500 uppercase tracking-tight">{t('contract_confirm_veh')}</span>
                  <span className="font-semibold text-zinc-800">{data.vehicle.model}</span>
                </div>
                <div className="flex justify-between border-b border-zinc-200/50 pb-1.5">
                  <span className="font-bold text-zinc-500 uppercase tracking-tight">{t('contract_confirm_plate')}</span>
                  <span className="font-mono font-semibold text-zinc-800 uppercase">{data.vehicle.plate}</span>
                </div>
                <div className="flex justify-between border-b border-zinc-200/50 pb-1.5">
                  <span className="font-bold text-zinc-500 uppercase tracking-tight">{t('contract_confirm_seller')}</span>
                  <span className="font-semibold text-zinc-800">
                    {data.seller.firstname} {data.seller.lastname}
                  </span>
                </div>
                <div className="flex justify-between border-b border-zinc-200/50 pb-1.5">
                  <span className="font-bold text-zinc-500 uppercase tracking-tight">{t('contract_confirm_buyer')}</span>
                  <span className="font-semibold text-zinc-800">
                    {data.buyer ? `${data.buyer.firstname} ${data.buyer.lastname}` : t('contract_authorized_buyer')}
                  </span>
                </div>
                <div className="flex justify-between pt-1.5">
                  <span className="font-bold text-zinc-500 uppercase tracking-tight">{t('contract_confirm_price')}</span>
                  <span className="font-bold text-concessionaire text-sm">
                    {formatPrice(data.vehicle.price)}
                  </span>
                </div>
                {!readOnly && (
                  <div className="flex justify-between pt-3 mt-1.5 border-t border-zinc-200/50 items-center">
                    <span className="font-bold text-zinc-500 uppercase tracking-tight">{t('contract_payment_method') || 'Método de Pagamento'}</span>
                    <div className="flex gap-2">
                      <button 
                        onClick={() => setPaymentMethod('bank')}
                        className={`px-3 py-1 text-xs font-bold rounded uppercase border ${paymentMethod === 'bank' ? 'bg-zinc-800 text-white border-zinc-800' : 'bg-transparent text-zinc-500 border-zinc-300 hover:border-zinc-400'}`}
                      >
                        Banco
                      </button>
                      <button 
                        onClick={() => setPaymentMethod('cash')}
                        className={`px-3 py-1 text-xs font-bold rounded uppercase border ${paymentMethod === 'cash' ? 'bg-green-600 text-white border-green-600' : 'bg-transparent text-zinc-500 border-zinc-300 hover:border-zinc-400'}`}
                      >
                        Dinheiro
                      </button>
                    </div>
                  </div>
                )}
              </div>
              
              {/* Action buttons using Custom UI buttons */}
              <div className="flex gap-4 w-full">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setShowConfirmModal(false)}
                  className="flex-1 border-zinc-400 hover:bg-zinc-100 text-zinc-700 font-bold uppercase tracking-wider text-[10px]"
                >
                  {t('contract_confirm_back')}
                </Button>
                <Button
                  variant="primary"
                  size="sm"
                  onClick={handleConfirmSignature}
                  className="flex-1 bg-concessionaire hover:bg-concessionaire-dark text-white font-bold uppercase tracking-wider text-[10px]"
                >
                  {t('contract_confirm_finalize')}
                </Button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Exit Hint */}
      <div className="absolute bottom-6 text-white/30 text-[10px] uppercase tracking-widest font-bold">
        {readOnly ? (
          <span>{t('contract_press_esc_back')}</span>
        ) : (
          <span>{t('contract_press_esc_cancel')}</span>
        )}
      </div>
    </div>
  );
};
