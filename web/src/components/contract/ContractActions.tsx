import React from 'react';
import { Button } from '../ui/button';
import { X, Check, PenLine } from 'lucide-react';

interface ContractActionsProps {
  onCancel: () => void;
  onConfirm: () => void;
  onSign?: () => void;
}

import { useLocale } from '../../context/LocaleContext';

export const ContractActions: React.FC<ContractActionsProps> = ({ onCancel, onConfirm, onSign }) => {
  const { t } = useLocale();
  return (
    <div className="fixed bottom-10 left-0 right-0 flex justify-center items-center space-x-6 z-50">
      <Button 
        variant="ghost" 
        onClick={onCancel}
        className="group"
      >
        <X className="w-4 h-4 mr-2 group-hover:text-red-500 transition-colors" />
        {t('contract_cancel')}
      </Button>
      
      <div className="flex items-center space-x-4 bg-zinc-900/50 backdrop-blur-md p-2 rounded-lg border border-white/10 shadow-2xl">
        {onSign && (
          <Button 
            variant="outline" 
            onClick={onSign}
            className="border-white/20 text-white hover:bg-white/10"
          >
            <PenLine className="w-4 h-4 mr-2" />
            {t('contract_sign')}
          </Button>
        )}
        
        <Button 
          variant="primary" 
          onClick={onConfirm}
          className="bg-concessionaire hover:bg-concessionaire-dark text-white px-10"
        >
          <Check className="w-4 h-4 mr-2" />
          {t('contract_confirm')}
        </Button>
      </div>
    </div>
  );
};
