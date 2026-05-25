import React from 'react';
import { Textarea } from '../ui/textarea';
import { MessageSquareText } from 'lucide-react';
import { useLocale } from '../../context/LocaleContext';

interface SellerObservationBoxProps {
  value: string;
  onChange: (value: string) => void;
}

export const SellerObservationBox: React.FC<SellerObservationBoxProps> = ({ value, onChange }) => {
  const { t } = useLocale();
  return (
    <div className="space-y-2">
      <label className="text-[10px] font-black text-zinc-400 uppercase tracking-widest flex items-center space-x-2">
        <MessageSquareText size={12} className="text-concessionaire" />
        <span>{t('sale_desc_label')}</span>
      </label>
      <div className="relative">
        <Textarea 
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={t('sale_desc_placeholder')}
          maxLength={150}
          className="bg-zinc-900 border-zinc-800 min-h-[60px] resize-none text-zinc-300 placeholder:text-zinc-800 text-[11px] leading-relaxed pb-6"
        />
        <div className="absolute bottom-1.5 right-2 text-[8px] font-bold text-zinc-600 uppercase tracking-widest">
          {value.length}/150
        </div>
      </div>
    </div>
  );
};
