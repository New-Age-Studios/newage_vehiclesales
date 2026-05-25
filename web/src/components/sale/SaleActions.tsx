import React from 'react';
import { Button } from '../ui/button';
import { CheckCircle2, XCircle } from 'lucide-react';

interface SaleActionsProps {
  onCancel: () => void;
  onConfirm: () => void;
  isValid: boolean;
}

export const SaleActions: React.FC<SaleActionsProps> = ({ onConfirm, isValid }) => {
  return (
    <div className="mt-6">
      <Button 
        disabled={!isValid}
        onClick={onConfirm}
        className="w-full bg-concessionaire hover:bg-concessionaire/90 text-black h-14 uppercase text-[10px] font-black tracking-widest disabled:opacity-50 rounded-xl shadow-[0_4px_15px_rgba(34,197,94,0.3)] transition-all active:scale-[0.98]"
      >
        <CheckCircle2 size={18} className="mr-2" />
        Anunciar Veículo para Venda
      </Button>
    </div>
  );
};
