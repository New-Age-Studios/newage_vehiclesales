import React, { useState } from 'react';
import { ContractData } from '../../types/contract';
import { ContractHeader } from './ContractHeader';
import { VehiclePhoto } from './VehiclePhoto';
import { VehicleInfo } from './VehicleInfo';
import { SellerInfo } from './SellerInfo';
import { PriceBox } from './PriceBox';
import { TermsBox } from './TermsBox';
import { SignatureArea } from './SignatureArea';
import { ContractFooter } from './ContractFooter';

interface VehicleContractProps {
  data: ContractData;
  onConfirm: () => void;
  onCancel: () => void;
}

export const VehicleContract: React.FC<VehicleContractProps> = ({ data, onConfirm, onCancel }) => {
  const [isSigned, setIsSigned] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);

  const handleSign = () => {
    if (isProcessing || isSigned) return;
    
    setIsSigned(true);
    setIsProcessing(true);
    
    // Simulate signing time before confirming
    setTimeout(() => {
      onConfirm();
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
            buyerName={isSigned ? (data.buyer ? `${data.buyer.firstname} ${data.buyer.lastname}` : "Comprador Autorizado") : undefined}
            date={data.date} 
            onSign={handleSign}
            isSigned={isSigned}
          />
          <ContractFooter />
        </div>
      </div>

      {/* Exit Hint */}
      <div className="absolute bottom-6 text-white/30 text-[10px] uppercase tracking-widest font-bold">
        Pressione <span className="text-white/60">ESC</span> para cancelar e sair
      </div>
    </div>
  );
};
